%% 
%% Author José Albert Cruz Almaguer <jalbertcruz@gmail.com>
%% Copyright 2011 by José Albert Cruz Almaguer.
%% 
%% This program is licensed to you under the terms of version 3 of the
%% GNU Affero General Public License. This program is distributed WITHOUT
%% ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING THOSE OF NON-INFRINGEMENT,
%% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Please refer to the
%% AGPL (http://www.gnu.org/licenses/agpl-3.0.txt) for more details.
%% 
%% 
%% @doc Módulo principal. Encargado de brindar los servicios,registra un proceso bajo el nombre de <g>.
%% 
-module(g).
-compile(export_all).

%% 
%% @doc Función de inicio, es la que debe usarse para levantar el proceso principal (denominado <g>), el colector (de nombre <colector>) y los procesos trabajadores (se crean inicialmente dada la cantidad especificada por parámetros).
%% 
s(NTrabajadores)->
    colector:start(NTrabajadores),
	profiler:start(),
    Pid = spawn(g, init,[]),
    register(g, Pid),
    ok.

%% 
%% @doc Función de inicio por defecto, construye 150 procesos trabajadores y levanta el colector y el proceso principal.
%% 
s()->
    colector:start(150),
    Pid = spawn(g, init,[]),
    register(g, Pid),
	profiler:start(),
    ok.

init()->
    loop().

%% 
%% @doc Dada una selección de cromosomas y funciones para obtener los pares a cruzar, el cruce y la mutación. Devuelve la nueva población.
%% 
iterar(Seleccion, FSeleccionPares, FCruce, FMutar)->
    Pares = FSeleccionPares(Seleccion),
    NuevosIndividuos = [FCruce(I) || I <- Pares],
    TInd = lists:append(Seleccion, NuevosIndividuos),
    PuntoDeMutacion = random:uniform(length(TInd) - 1),
    {Pre, [X|Post]} = lists:split(PuntoDeMutacion - 1, TInd),
    XMutado = FMutar(X),
    [XMutado | lists:append(Pre, Post)].

loop()->
  receive
  
      %% Mensaje que dado un número <N> y una función <FF> le manda un mensaje equivalente al <colector> (aumenta la cantiadd de trabajores).
      {addW, N, FF} ->
	  colector ! {addW, N, FF},
	  loop();

      %% Mensaje que dado un número <N> le manda un mensaje equivalente al <colector> (disminuye la cantidad de trabajadores).
      {remW, N} ->
	  colector ! {remW, N},
	  loop();

      %% Mensaje que dada una función <NF> le manda un mensaje equivalente al <colector>
      %% (camiando la función de fitness que se usa en los trabajadores).
      {chfitness, NF} ->
	  colector ! {chfitness, NF},
	  loop();

      %% Aplicación de un caso de pruebas con 150 individuos y cromosomas de 8 genes.
      {calc, Generaciones} ->
	  {A1,A2,A3} = now(),
	  random:seed(A1,A2,A3),
	  profiler ! {inicioEvolucion, now()},
	  colector ! {filtrar, g:gp(50, 8), Generaciones},
	  loop();

      %% Mensaje mediante el que se le pide a <g> que calcule para una población <Población> y una cantidad de generaciones <Generaciones> la población resultante.
      {calc, Poblacion, Generaciones} ->
	  {A1,A2,A3} = now(),
	  random:seed(A1,A2,A3),
	  profiler ! {inicioEvolucion, now()},
	  colector ! {filtrar, Poblacion, Generaciones},
	  loop();

      %% Se han realizado todas las iteraciones (mensaje privado)
      {itera, Seleccion, N} when N == 0 ->
	  Res = iterar(Seleccion, fun g:seleccionPares/1, fun g:cruce/1,fun  g:mutar/1),
	  self() ! {calculado, Res}, % Reporte de la solución
	  loop();
		
      %% 
      {itera, Seleccion, N} when N > 0 ->
	  Res = iterar(Seleccion, fun g:seleccionPares/1, fun g:cruce/1,fun  g:mutar/1),
	  colector ! {filtrar, Res, N},
	  loop();

      {calculado, Res} ->
	  profiler ! {finEvolucion, now()}, %% Fin del calculo
	  io:format("Poblacion final de ~p cromosomas:~n", [length(Res)]),
	  imprimirPoblacion(Res),
	  loop();
	  
      terminar  ->
	  colector ! terminar,
	  profiler ! terminar,
	  ok

  end.

%% 
%% @doc En el caso de esta funcion he decidido no usar los esclavos dado que es utilitaria (ver los individuos)...
%% 
imprimirPoblacion(P)->
    Pares = [ {trabajador:fitness(I), I} || I <- P ],
    Lista = lists:keysort(1, Pares),
    lists:foreach(
      fun({F, C}) -> 
	      io:format("Cromosoma: ~p con fitness: ~p~n", [C, F])
      end, 
      Lista).

seleccionPares(P) ->
    Pivote = length(P) div 2,
    {A, B} = lists:split(Pivote, P),
    lists:zip(A, B).

% TODO: Probar varias veces
cruce(Parent1, Parent2, Pivote1, Pivote2)->
    {Frag1, _} = lists:split(Pivote1, Parent1),
    {_, Frag3} = lists:split(Pivote2, Parent1),
    Frag2 = lists:sublist(Parent2, Pivote1, Pivote2-Pivote1),
    Frag1 ++ Frag2 ++ Frag3.

% TODO: Probar varias veces
%% 
%% @doc Cruce usando dos puntos, se genera uno de ellos y luego el segundo se obtiene de forma también aleatoria hacia el extremo derecho del primero.
%% 
cruce({P1, P2})->
    Pivote1 = random:uniform(length(P1) - 1),
    Pivote2 = Pivote1 + random:uniform(length(P1) - Pivote1),
    cruce(P1, P2, Pivote1, Pivote2).

%% 
%% @doc Dado un cromosoma realiza una mutación en un gen aleatorio.
%% 
mutar(S)->
    MutationPoint = random:uniform(length(S)-1),
    {Pre, [X|Post]} = lists:split(MutationPoint-1, S),
    P = probability(1),
    Ngen = if P -> if X == 1 -> 0; true -> 1 end; true -> X end,
    Pre ++ [Ngen | Post].

generarCromosoma(Tam)->
    generarCromosomaAux(Tam).

generarCromosomaAux(0) -> [];
generarCromosomaAux(N) -> 
    [random:uniform(2)-1 | generarCromosomaAux(N - 1)].

generarPoblacionAux(1, NCromosomas)-> [generarCromosoma(NCromosomas)];
generarPoblacionAux(N, NCromosomas) -> [generarCromosoma(NCromosomas) | generarPoblacionAux(N - 1, NCromosomas)].

%% 
%% @doc Generador de poblaciones, por razones de comodidad en esta versión se generan múltiplos de 3.
%% 
gp(Tam, NCromosomas)->
    TReal = Tam * 3,
    generarPoblacionAux(TReal, NCromosomas).

% A simple probability function that returns true with 
% a probability of 1/2^X
probability(X)-> probability(X, X).
probability(_, 0) -> true;
probability(X, A) ->
    N1 = random:uniform(),
    N2 = random:uniform(),
    case N1 > N2 of
        true -> probability(X, A-1);
        false -> false
    end.

fitness0(L) ->
    length(lists:filter(fun(X) -> X == 0 end, L)) * 2.

fitnessL(L) ->
    fitness(0, L).

%% 
%% @doc Cálculo de la longitud de la subcadena con la cantidad máxima de 1s.
%% 
fitness(Max, [])->
    Max;
fitness(Max, [0|R]) ->
    fitness(Max, R);
fitness(Max, [1|R]) ->
   {Pre, Suf}= lists:splitwith(fun(X)-> X == 1 end, [1|R]),
    fitness(max(Max, length(Pre)), Suf).

## 
## Author José Albert Cruz Almaguer <jalbertcruz@gmail.com>
## Copyright 2011 by José Albert Cruz Almaguer.
## 
## This program is licensed to you under the terms of version 3 of the
## GNU Affero General Public License. This program is distributed WITHOUT
## ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING THOSE OF NON-INFRINGEMENT,
## MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Please refer to the
## AGPL (http://www.gnu.org/licenses/agpl-3.0.txt) for more details.
## 
project = 'PoolBased'

Dir.chdir('./PoolBased/src')
puts "cd #{project}/src"

Dir["*.erl"].each { |e|
 puts "Compilando #{e}", %x{"erlc" #{e}}
}

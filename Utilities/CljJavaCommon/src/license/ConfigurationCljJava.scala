package license

import collection.mutable.HashTable
import java.io.File
import collection.immutable.Map
import collection.mutable.ListBuffer
import scala.collection.JavaConversions._
import clojure.lang._
import license.FileUtility._

class ConfigurationCljJava(cljScript: String, expression: String) {

  protected[this] var associations: Map[String, String] = Map[String, String]()
  protected[this] var root: File = null
  protected[this] var excluded: ListBuffer[File] = new ListBuffer[File]()
  protected[this] var header: String = _
  protected[this] var header_lines_count: Int = _

  def Excluded(f: File): Boolean = !excluded.contains(f)

  RT.loadResourceScript(cljScript)

  var map: PersistentHashMap = Compiler.eval(RT.readString("(eval '" + expression + ")")).asInstanceOf[PersistentHashMap]

  // Determinación de los excluidos:
  var pv: PersistentVector = map.get(Keyword.intern("excluded")).asInstanceOf[PersistentVector]

  var it = pv.iterator()
  while (it.hasNext) {
    val g = it.next().asInstanceOf[String]
    excluded += new File(g)
  }

  pv = map.get(Keyword.intern("associations")).asInstanceOf[PersistentVector]

  it = pv.iterator()
  while (it.hasNext) {
    val g = it.next().asInstanceOf[PersistentVector]
    associations += (g.get(0).asInstanceOf[String] -> g.get(1).asInstanceOf[String])
  }

  header = map.get(Keyword.intern("header")).asInstanceOf[String]

  header_lines_count = header.split("\n").length

  root = new File(map.get(Keyword.intern("root")).asInstanceOf[String])

  protected[this] def Prefix(f: File) = {
    var res = "";
    associations.keys.foreach {
      k =>
        if (f.getName.endsWith(k))
          res = associations(k)
    }
    res
  }
  
   protected[this] def isExcluded(f: File): Boolean = {
        var exc = false
        val it = excluded.iterator()
        while(it.hasNext() && !exc) {
            var file = it.next()
            if (file.equals(f)) {
                exc = true
            }
        }
        exc
    }

}
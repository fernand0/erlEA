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

Dir.chdir('Utilities/License_aplicator/')
puts Dir.pwd
puts %x{ant.bat run}

Dir.chdir('../Update_erl_from_clj/')
puts Dir.pwd
puts %x{ant.bat runMasterSlaveModel}
puts %x{ant.bat runIslandModel}
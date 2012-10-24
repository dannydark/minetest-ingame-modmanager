package.cpath = package.cpath .. ";/usr/lib/lua/5.1/?.so"
package.path = package.path .. ";/usr/lib/lua/5.1/?.lua"
package.cpath = package.cpath .. ";/usr/lib/lua/5.2/?.so"
package.path = package.path .. ";/usr/lib/lua/5.2/?.lua"

ltn12 = require ("ltn12")
ftp = require   ("socket.ftp")
zip = require   ("zip")

--from http://lua-users.org/wiki/SaveTableToFile

do
   -- declare local variables
   --// exportstring( string )
   --// returns a "Lua" portable version of the string
   local function exportstring( s )
      return string.format("%q", s)
   end

   --// The Save Function
   function table.save(  tbl,filename )
      local charS,charE = "   ","\n"
      local file,err = io.open( filename, "wb+" )
      if err then return err end

      -- initiate variables for save procedure
      local tables,lookup = { tbl },{ [tbl] = 1 }
      file:write( "return {"..charE )

      for idx,t in ipairs( tables ) do
         file:write( "-- Table: {"..idx.."}"..charE )
         file:write( "{"..charE )
         local thandled = {}

         for i,v in ipairs( t ) do
            thandled[i] = true
            local stype = type( v )
            -- only handle value
            if stype == "table" then
               if not lookup[v] then
                  table.insert( tables, v )
                  lookup[v] = #tables
               end
               file:write( charS.."{"..lookup[v].."},"..charE )
            elseif stype == "string" then
               file:write(  charS..exportstring( v )..","..charE )
            elseif stype == "number" then
               file:write(  charS..tostring( v )..","..charE )
            end
         end

         for i,v in pairs( t ) do
            -- escape handled values
            if (not thandled[i]) then
            
               local str = ""
               local stype = type( i )
               -- handle index
               if stype == "table" then
                  if not lookup[i] then
                     table.insert( tables,i )
                     lookup[i] = #tables
                  end
                  str = charS.."[{"..lookup[i].."}]="
               elseif stype == "string" then
                  str = charS.."["..exportstring( i ).."]="
               elseif stype == "number" then
                  str = charS.."["..tostring( i ).."]="
               end
            
               if str ~= "" then
                  stype = type( v )
                  -- handle value
                  if stype == "table" then
                     if not lookup[v] then
                        table.insert( tables,v )
                        lookup[v] = #tables
                     end
                     file:write( str.."{"..lookup[v].."},"..charE )
                  elseif stype == "string" then
                     file:write( str..exportstring( v )..","..charE )
                  elseif stype == "number" then
                     file:write( str..tostring( v )..","..charE )
                  end
               end
            end
         end
         file:write( "},"..charE )
      end
      file:write( "}" )
      file:close()
   end
   
   --// The Load Function
   function table.load( sfile )
      local ftables,err = loadfile( sfile )
      if err then return _,err end
      local tables = ftables()
      for idx = 1,#tables do
         local tolinki = {}
         for i,v in pairs( tables[idx] ) do
            if type( v ) == "table" then
               tables[idx][i] = tables[v[1]]
            end
            if type( i ) == "table" and tables[i[1]] then
               table.insert( tolinki,{ i,tables[i[1]] } )
            end
         end
         -- link indices
         for _,v in ipairs( tolinki ) do
            tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
         end
      end
      return tables[1]
   end

   function table.loadfromstring( string )
      local ftables,err = loadstring( string )
      if err then return _,err end
      local tables = ftables()
      for idx = 1,#tables do
         local tolinki = {}
         for i,v in pairs( tables[idx] ) do
            if type( v ) == "table" then
               tables[idx][i] = tables[v[1]]
            end
            if type( i ) == "table" and tables[i[1]] then
               table.insert( tolinki,{ i,tables[i[1]] } )
            end
         end
         -- link indices
         for _,v in ipairs( tolinki ) do
            tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
         end
      end
      return tables[1]
   end
-- close do
end

function dump(o)
if type(o) == 'table' then
local s = '{ '
for k,v in pairs(o) do
if type(k) ~= 'number' then k = '"'..k..'"' end
s = s .. '['..k..'] = ' .. dump(v) .. ','
end
return s .. '} '
else
return tostring(o)
end
end

MODLIST_URL = "ftp://ftp1853953:minetest@ftp-web.funpic.de:21/mods.list"
TEMP_MODLISTCACHE = "modlist.cache"

function get_modlist(gamepath)
	f = io.open(gamepath..TEMP_MODLISTCACHE, "r")
	if f then
		local r = f:read("*all")
		f:close()
		return r, nil
	else
		return ftp.get(MODLIST_URL)
	end
end

function mkdir (folderpath)
	return os.execute("mkdir " .. folderpath)
end

function installmod (url, destpath)
	TEMP_MODPATH = destpath.."mod.temp"
	f, e = io.open(TEMP_MODPATH, "wb+")
	if (e~=nil) then
		return "Error: "..e.."\n Do you have write permission?"
	end

	print("1/3 Downloading Mod")
	s, e = ftp.get({
		url = url,
		sink = ltn12.sink.file(f),
		type = "i",
	})
	if (e~=nil) then
		return "Error: "..e.."\n Mod package could not be downloaded"
	end

	print("2/3 Unpacking Mod")
	zfile = zip.open(TEMP_MODPATH);
	zfile:files()
	for file in zfile:files() do
		o = io.open(destpath..file.filename, "wb+")
		s = zfile:open(file.filename)
		if (o and s) then --is file
			ltn12.pump.all(ltn12.source.file(s), ltn12.sink.file(o))
		else --is folder
			local e = mkdir(destpath..file.filename)
			if (e~=0) then --256=error 0=success
				return e..": could not create mod directory"
			end
		end
	end

	print("3/3 Finishing installation")
	os.remove(TEMP_MODPATH)
	print("Mod installation successfully finished!")
	return nil;
end

function removedir(path)
	return os.execute("rm -r --interactive=never "..path)
end

--Functions called by Minetest:

function modmanager_refresh (gamepath)
	print("Refreshing mod list...")
	s, e = ftp.get(MODLIST_URL)
	if (e) then
		return _, e
	end
	local list = table.loadfromstring(s)
	f = io.open(gamepath..TEMP_MODLISTCACHE, "wb+")
	if f then
		f:write(s)
		f:close()
	end

	local i = 1
	local modnames = {}
	while list[i]~=nil do
		modnames[i] = list[i].name
		print ( list[i].name )
		i = i + 1
	end

	return modnames, nil
end

function modmanager_info (modname, gamepath)
	s, e = get_modlist(gamepath)
	if (e) then
		return nil, nil, nil, nil
	end
	local list = table.loadfromstring(s)

	local i = 1
	while list[i]~=nil do
		if list[i].name == modname then
			return  list[i].name,
				list[i].url,
				list[i].description,
				tonumber(list[i].version)
		end
		i = i + 1
	end

	return nil, nil, nil, nil
end

function modmanager_install (modname, destpath, gamepath) --dest = "games/gamename/mods/"
	print("Installing mod: "..modname)
	s, e = get_modlist(gamepath)
	if (e) then
		return e
	end

	local list = table.loadfromstring(s)

	local i = 1
	while list[i]~=nil do
		if list[i].name == modname then
			return installmod(list[i].url, destpath)
		end
		i = i + 1
	end

	return "Strange Exception... Try to refresh the modlist"
end

function modmanager_uninstall (modpath) --dest = "games/gamename/mods/"	
	local result = removedir (modpath)
	if result ~= 0 then
		return result
	end
	return nil;
end

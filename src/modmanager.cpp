/*
Minetest-c55
Copyright (C) 2011 celeron55, Perttu Ahola <celeron55@gmail.com>
Copyright (C) 2012 Florian Euchner <florian.euchner@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include <iostream>

#include "log.h"
#include "script.h"
#include "subgame.h"
#include "porting.h"
#include "filesys.h"

#include "modmanager.h"

ModManager::ModManager(std::string path_to_subgame)
{
	game_path = path_to_subgame;
}


ModManager::~ModManager()
{
}

std::string *ModManager::read_modlist(lua_State *L, int index)
{
	std::string *result = new std::string[1023];
	if (!lua_istable(L,index))
		return NULL;

	lua_pushnil(L);

	if(index < 0)
		index -= 1;
	while(lua_next(L, index) != 0){
		/*printf("%f - %s\n",
              	luaL_checknumber(L, -2),
              	luaL_checkstring(L, -1));*/
		result[int(luaL_checknumber(L, -2))] = luaL_checkstring(L, -1);
		// removes value, keeps key for next iteration
		lua_pop(L, 1);
	}

	return result;
}

std::string *ModManager::refresh()
{
	std::string *error = new std::string[1];

	lua_State *L = script_init();
	std::string scriptpath = game_path + DIR_DELIM + "modmanager.lua";
	if (!fs::PathExists(scriptpath))
	{
		error[0] = "error.oldgame";
		return error;
	}
	if (luaL_loadfile(L, scriptpath.c_str()) || lua_pcall(L, 0, 0, 0))
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		error[0] = "error.lua";
		return error;
	}
	lua_getglobal(L, "modmanager_refresh");
	lua_pushstring(L, (game_path + DIR_DELIM).c_str());
	if (lua_pcall(L, 1, 2, 0))
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		error[0] = "error.lua";
		return error;
	}

	if (!lua_isnil(L, 2))
	{
		errorstream<<lua_tostring(L, 2)<<std::endl;
		error[0] = "error.modlist";
		return error;
	}
	std::string *modnames;
	modnames = read_modlist(L, 1);

	script_deinit(L);
	return modnames;
}

std::string ModManager::install(const char* modname)
{
	std::string destpath;
	destpath = game_path + DIR_DELIM + "mods" + DIR_DELIM;
	std::string scriptpath = game_path + DIR_DELIM + "modmanager.lua";

	lua_State *L = script_init();
	if (luaL_loadfile(L, scriptpath.c_str()) || lua_pcall(L, 0, 0, 0)) 
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		return "error.lua";
	}
	lua_getglobal(L, "modmanager_install");
	lua_pushstring(L, modname);
	lua_pushstring(L, destpath.c_str());
	lua_pushstring(L, (game_path + DIR_DELIM).c_str());

	if (lua_pcall(L, 3, 1, 0))
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		return "error.lua";
	}
	
	if (!lua_isnil(L, 1))
	{
		errorstream<<lua_tostring(L, 1)<<std::endl;
		return "error.install";
	}

	script_deinit(L);
	return "";
}

std::string ModManager::uninstall(const char* modname)
{
	std::string scriptpath = game_path + DIR_DELIM + "modmanager.lua";
	std::string modpath = game_path + DIR_DELIM + "mods" + DIR_DELIM + modname + DIR_DELIM;
	lua_State *L = script_init();

	if (luaL_loadfile(L, scriptpath.c_str()) || lua_pcall(L, 0, 0, 0)) 
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		return "error.lua";
	}

	lua_getglobal(L, "modmanager_uninstall");
	lua_pushstring(L, modpath.c_str());

	if (lua_pcall(L, 1, 1, 0))
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		return "error.lua";
	}

	if (!lua_isnil(L, 1))
	{
		errorstream<<lua_tostring(L, 1)<<std::endl;
		return "error.uninstall";
	}

	script_deinit(L);
	return "";
}

ModManagerSpec ModManager::info(const char* modname)
{
	ModManagerSpec spec;
	std::string scriptpath = game_path + DIR_DELIM + "modmanager.lua";
	lua_State *L = script_init();

	if (luaL_loadfile(L, scriptpath.c_str()) || lua_pcall(L, 0, 0, 0)) 
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		spec.name = "error.lua";
		return spec;
	}

	lua_getglobal(L, "modmanager_info");
	lua_pushstring(L, modname);
	lua_pushstring(L, (game_path + DIR_DELIM).c_str());

	if (lua_pcall(L, 2, 4, 0))
	{
		errorstream<<lua_tostring(L, -1)<<std::endl;
		spec.name = "error.lua";
		return spec;
	}

	if (lua_isnil(L, 1))
	{
		errorstream<<lua_tostring(L, 1)<<std::endl;
		spec.name = "error.info";
		return spec;
	}

	spec.name = lua_tostring(L, 1);
	spec.url = lua_tostring(L, 2);
	spec.description = lua_tostring(L, 3);
	spec.version = lua_tonumber(L, 4);

	script_deinit(L);
	return spec;
}

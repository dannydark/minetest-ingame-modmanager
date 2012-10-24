/*
Part of Minetest-c55
Copyright (C) 2010-2011 celeron55, Perttu Ahola <celeron55@gmail.com>
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


#include <string>
extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#ifndef MODMANAGER_HEADER
#define MODMANAGER_HEADER

struct ModManagerSpec
{
	std::string name;
	std::string url;
	std::string description;
	int version;
};

class ModManager
{
public:
	ModManager(std::string path_to_subgame);
	~ModManager();

	std::string *refresh();
	std::string install   (const char* modname);
	std::string uninstall (const char* modname);
	ModManagerSpec info(const char* modname);

private:
	std::string *read_modlist(lua_State *L, int index);
	std::string game_path;
};

#endif

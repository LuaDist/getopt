# Copyright (C) 2007-2009 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( getopt NONE )
cmake_minimum_required ( VERSION 2.6 )
include ( cmake/dist.cmake )
include ( lua )

# Install all files and documentation
install_lua_module ( getopt getopt.lua )

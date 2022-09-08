# SPDX-License-Identifier: Apache-2.0
#
# PPPMake - Convinient make file for exercises and tryouts
#
# This make file is capable for adding recipes dynamically. In this project's
# context a program is built by converting one or more C/C++ source codes into
# a binary, ie. no intermediate .o files.
#
# Each program has three components,
# 	1. program name
# 	2. module (root directory for source files)
# 	3. a list of source files
# One can add a recipe to make a program as follows,
#   PROGRAM=<program_name>:<module>:<source-1>[,source-2,...] make add
# eg.
# 	PROGRAM=hello_world:2-hello-world:main.cc,hello.cc make add
# This will add a recipe effectively identical to following,
#
#   hello_world: build/hello_world
#   build/hello_world: src/2-hello-world/main.cc src/2-hello-world/hello.cc
#       $(compiler) $(cpp_flags) $(compiler_flags) -I<dirs>... -o $@ $^
#
# For convinience, finally made target will be recorded in .last_make file
# so that next time .DEFAULT_GOAL is set to that target.
#
# Alternatively, NAME, MODULE, and SOURCES variables can be used to define
# programs, Same effect as the above example can be obtained by following command:
#   NAME=hello_world MODULE=2-hello-world SOURCES=main.cc,hello.cc make add
#
# NOTE: due to the nature of this project, compile_commands.json may not make sense sometimes.
# Since it only has the description of the files for one executable among many, rebuilding it and
# LSP restart would be necessary when working on a different program.

include Makefile.info

project_root = $(realpath $(CURDIR))
build_dir = $(project_root)/build
source_dir = $(project_root)/src
include_dirs += $(project_root)/include

cpp_flags += $(CPPFLAGS)
includes = $(addprefix -I, $(include_dirs))

# some colors for eye catching output
c.fail = \e[1;31m
c.succ = \e[1;32m
c.info = \e[1;34m
c.norm = \e[0m

# To rebuild the compile_command.json for a specific target use BEAR=1
# eg: BEAR=1 make hello_world
ifeq ($(BEAR),1)
	bear = bear --
else
	bear =
endif

# Enable debug compiler flags
ifeq ($(DEBUG),1)
	debug = $(debug_flags)
else
	debug =
endif

targets_list =

# function for generating rules to generate target binaries
# for a set of C++ source files
define generate_target_rule
targets_list += $(1)
# without this intermediate recipe, make cannot deduce if it is needed to build again
# because the actual target name is different from produced file
$(1): $(addprefix $(build_dir)/, $(1)) | ${build_dir}
$(addprefix $(build_dir)/, $(1)): $(addprefix $(source_dir)/, $(addprefix $(2)/, $(3)))
	@echo -en "$(c.info)==>$(c.norm) TARGET: "
	@echo $(1) | tee .last_make
	@echo -en "    Building $$@ ...\n    "
	$(hide)$(bear) $(compiler) $(cpp_flags) $(compiler_flags) $(debug) $(includes) -o $$@ $$^
	@echo -e  "$(c.succ)***$(c.norm) DONE." # these start and end messages are useful when making with emacs
endef

.PHONY: notarget clean cc.json add reset list

emptyness =
.DEFAULT_GOAL = $(shell cat .last_make 2> /dev/null)
ifeq ($(.DEFAULT_GOAL), $(emptyness))
	.DEFAULT_GOAL = notarget
else
endif
notarget:
	@echo -e "$(c.fail)***$(c.norm) No build history found. Please specify a target"

clean:
	@echo -e "$(c.info)==>$(c.norm) CLEAN"
	@echo    "    Emptying build/ dir"
	@rm -rf build/
	@mkdir build
	@echo -e "$(c.succ)***$(c.norm) DONE."

cc.json: clean
	@echo -e "$(c.info)==>$(c.norm) REBUILD compile_commands.json"
	bear -- $(MAKE) $(targets_list)
	@echo -e "$(c.succ)***$(c.norm) DONE."

reset: clean
	@echo -e "$(c.info)==>$(c.norm) RESET"
	@echo    "    Clearing build history"
	@rm -f .last_make
	@echo -e "$(c.succ)***$(c.norm) DONE."

list:
	@echo -e "$(c.info)==>$(c.norm) LIST"
	@echo    "    Current targets list"
	@echo    "        " $(targets_list)
	@echo -e "$(c.succ)***$(c.norm) DONE."

${build_dir}:
	mkdir ${build_dir}

# Bring the actual targets
include Makefile.targets

# Read and parse inputs
comma = ,
ifneq ($(PROGRAM),)
# turn commas into spaces and colons into commas (for 'call' expressions)
# PROGRAM=A:B:S1,S2  ==> generator_args=A,B,S1 S2
	generator_args = $(subst :,$(comma),$(subst $(comma), ,$(strip $(PROGRAM))))
# populate specific variables
# This requires generator_args to be a list as A B S1 S2
	generator_list = $(subst $(comma), ,$(generator_args))
	target_name = $(word 1,$(generator_list))
	module_name = $(word 2,$(generator_list))
	source_list = $(wordlist 3,$(words $(generator_list)),$(generator_list))
	missing = "none"
else ifndef NAME
	missing = "NAME"
else ifndef MODULE
	missing = "MODULE"
else ifndef SOURCES
	missing = "SOURCES"
else
# all sufficient variables are defined
	target_name = $(strip $(NAME))
	module_name = $(strip $(MODULE))
	source_list = $(subst $(comma), ,$(strip $(SOURCES)))
	generator_args = $(target_name),$(module_name),$(source_list)
	missing = "none"
endif

ifeq ($(missing),)
	missing = "one of: PROGRAM or (NAME,MODULE,SOURCES)"
endif

# Check if the target is already added. CHECK will be empty if not
check = $(addprefix test-,$(filter $(target_name),$(targets_list)))

# Populate generator variables: GENERATOR_EXP will be executed when making ADD target
ifeq ($(check),)
	generator_exp = '$$(eval $$(call generate_target_rule, $(generator_args)))\n' >> Makefile.targets
	module_dir = $(source_dir)/$(module_name)
	source_files = $(addprefix $(source_dir)/, $(addprefix $(module_name)/,$(source_list)))
	rule_end = "$(c.succ)***$(c.norm) DONE."
else
	generator_exp = "$(c.fail)***$(c.norm) Target \"$(target_name)\" alrady exists "
	rule_end = "$(c.fail)***$(c.norm) DONE."
endif

ifeq ($(generator_args),)
	generator_exp = "$(c.fail)***$(c.norm) Please specify the necessary variable(s). Following is missing:\n        $(missing)"
	rule_end = "$(c.fail)***$(c.norm) DONE."
endif

add:
	@echo -e "$(c.info)==>$(c.norm) ADD PROGRAM: $(generator_args)"
	@echo -e $(generator_exp)
	@echo -e "$(c.info)==>$(c.norm) CREATE FILES:"
	@if [ ! -d $(module_dir) ]; then mkdir -v $(module_dir); fi
	@for file in $(source_files); do echo -e "\t$${file}"; touch $${file}; done
	@echo -e $(rule_end)

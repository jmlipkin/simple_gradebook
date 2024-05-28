################################################################################
#
# Universal (mostly) Makefile for ECE114
# 12/29/2023 William Moon
#
# This Makefile can be placed in any directory without modification, and that
# the goal is that building and debugging will "just work". 
# 
# It assumes that all .c, .h, and .cpp files in the current directory should be
# compiled and linked together. If all the source files are .c files, it will
# use gcc as the compiler. Otherwise, it will use g++.
# 
# It puts object and dependency files in a subdirectory called .build.
# 
# It tries to figure out which source file contains the main() function, and
# will name the executable based on that filename. It also creates a file called
# .build/debug (.build\debug.exe on windows), which is referenced in tasks.json
# for use in debugging. 
# 
# There is a "clean" target for getting rid of all build artifacts, including
# any .zip files.
# 
# There is a "zip" target for creating a zip of all the source code. The zipfile
# is named based on the current directory name and the user name.  For best
# results, create an environment variable called FULL_NAME, and name the current
# directory based on the assignment you're working on.
# 
################################################################################

# Check that everything make needs has been installed. Account for any 
# difference in the OS we're running on.
ifeq ($(OS),Windows_NT)		# OS is windows NT or later
  DETECTED_OS := Windows
  # Point to msys tools, not the built-in ones from microsoft
  USR_BIN := $(dir $(shell which which))
  ifeq ("$(wildcard $(USR_BIN))","")
    $(error MSYS tools not installed properly.)
  endif
  FIND := $(join $(USR_BIN), find)
  ifeq ("$(wildcard $(FIND))","")
    $(error Could not find MSYS version of "find". Check MSYS installation)
  endif
  MKDIR := $(join $(USR_BIN), mkdir)
  ifeq ("$(wildcard $(MKDIR))","")
    $(error Could not find MSYS version of "mkdir". Check MSYS installation)
  endif
  RM := $(join $(USR_BIN), rm -f)
  ifeq ("$(wildcard $(RM))","")
    $(error Could not find MSYS version of "rm". Check MSYS installation)
  endif
  ZIP := $(join $(USR_BIN), zip)
  ifeq ("$(wildcard $(ZIP))","")
    $(error Could not find MSYS version of "zip". Check MSYS installation)
  endif
else
  DETECTED_OS := $(shell uname)
  FIND := find
  MKDIR := mkdir
  RM := rm -f
  ZIP := zip
endif

CC := gcc 
CFLAGS := -g -std=gnu11 -Wall -Werror
CXX := g++
CXXFLAGS := -g -std=gnu++11 -Wall -Werror
LDFLAGS := -lm

ifneq ($(DETECTED_OS),Darwin)
  FOO := $(shell $(ZIP) --help)
  ifneq ($(.SHELLSTATUS),0)
    $(error "zip" is not installed, which is needed by make)
  endif
  FOO := $(shell $(FIND) --help)
  ifneq ($(.SHELLSTATUS),0)
    $(error "find" is not installed, which is needed by make)
  endif
  FOO := $(shell nm --help)
  ifneq ($(.SHELLSTATUS),0)
    $(error "nm" is not installed, which is needed by make)
  endif
  FOO := $(shell grep --help)
  ifneq ($(.SHELLSTATUS),0)
    $(error "grep" is not installed, which is needed by make)
  endif
  FOO := $(shell cut --help)
  ifneq ($(.SHELLSTATUS),0)
    $(error "cut" is not installed, which is needed by make)
  endif
endif

ifneq ($(DETECTED_OS),Darwin)
  ifneq ($(DETECTED_OS),Windows)
    CFLAGS += -fsanitize=address
    CXXFLAGS += -fsanitize=address
    LDFLAGS += -fsanitize=address
  endif
endif


.DEFAULT_GOAL := all
# Add .d to Make's recognized suffixes.
SUFFIXES += .d


# We don't need to find dependencies when we're making these targets
NODEPS:=clean zip

.PHONY: all clean zip

BUILD_DIR := .build
DEBUG_EXE := $(BUILD_DIR)/debug

# Use FULL_NAME if we have it. Otherwise, use USER or USERNAME
ifdef FULL_NAME
  NAME := $(FULL_NAME)
else
  ifdef USER
    NAME := $(USER)
  else
    ifdef USERNAME
      NAME := $(USERNAME)
    else
      NAME :=
    endif
  endif
endif
CUR_DIR := $(notdir $(shell pwd))
ifeq ($(DETECTED_OS),Darwin)
  ZIP_FILES := $(shell $(FIND) . -maxdepth 1 -type f ! -perm +111 ! -path '*.zip' ! -path '*.o' )
else
  ZIP_FILES := $(shell $(FIND) . -maxdepth 1 -type f,l ! -executable ! -path '*.zip' ! -path '*.o' )
endif

# Find all the C and C++ files in the source directory
SOURCES := $(shell $(FIND) . -maxdepth 1 -type f,l -name "*.cpp" -o -name "*.c")

# If there are any .cpp files, then use C++ compiler to link. Otherwise use C compiler
ifneq ("$(wildcard *.cpp)", "")
  MY_CC := $(CXX)
else
  MY_CC := $(CC)
endif

DEPFILES := $(patsubst %.cpp,$(BUILD_DIR)/%.d,$(notdir $(SOURCES)))
DEPFILES := $(patsubst %.c,$(BUILD_DIR)/%.d,$(DEPFILES))

OBJFILES := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(notdir $(SOURCES)))
OBJFILES := $(patsubst %.c,$(BUILD_DIR)/%.o,$(OBJFILES))

# Don't create dependencies for clean and zip
ifeq (0, $(words $(filter $(NODEPS), $(MAKECMDGOALS))))
  -include $(DEPFILES)
endif

# If we've previously figured out our executable name, then get that and 
# create a dependency that copies our debug exe to our "real" exe name
EXE_MAK := $(BUILD_DIR)/exe.mak
ifneq ("$(wildcard $(EXE_MAK))","")
  -include $(EXE_MAK)
  all: $(EXE) $(EXE_MAK)
  $(EXE): $(DEBUG_EXE) ; cp $(DEBUG_EXE) $(EXE)
else
  all: $(EXE_MAK)
endif

# Rule to figure out our exe name, and create the exe.mak file
$(EXE_MAK): $(DEBUG_EXE)
	$(eval MAIN_O := $(shell nm --print-file-name --demangle $(OBJFILES) | grep " T _\?main" | cut -f1 -d:))
	$(eval EXE_NAME := $(notdir $(basename $(MAIN_O))))
	$(info setting executable name to $(EXE_NAME) because main() was found in $(MAIN_O))
	$(eval FOO := $(shell echo 'EXE := $(EXE_NAME)' > $(EXE_MAK)))
ifndef EXE
	cp $(DEBUG_EXE) $(EXE_NAME)
endif

# Rule to build the executable by linking the object files
$(DEBUG_EXE): $(OBJFILES)
	$(MY_CC) -o $@ $(LDFLAGS) $^
	
# Rule to compile .c files
$(BUILD_DIR)/%.o: %.c $(BUILD_DIR)/%.d | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ -c $<

# Rule to compile .cpp files
$(BUILD_DIR)/%.o: %.cpp $(BUILD_DIR)/%.d | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $@ -c $<

# Rule to create the dependency files for .c files
$(BUILD_DIR)/%.d: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -MM -MT '$(patsubst %.c,$(BUILD_DIR)/%.o,$<)' $< -MF $@

# Rule to create the dependency files for .cpp files
$(BUILD_DIR)/%.d: %.cpp | $(BUILD_DIR)
	$(CXX) $(CxxFLAGS) -MM -MT '$(patsubst %.cpp,$(BUILD_DIR)/%.o,$<)' $< -MF $@

# Rule to make the build directory
$(BUILD_DIR):
	$(MKDIR) -p $(BUILD_DIR)

# Rule to make a zip file. All non-executable, non-object, non zip files in the
# current directory are zipped.
zip:
	$(ZIP) $(NAME)_$(CUR_DIR).zip $(ZIP_FILES)

# Rule to clean everything in the build directory, our exe, and the zipfile
clean:
	$(RM) -r $(BUILD_DIR)
	$(RM) *.zip
ifdef EXE
	$(RM) $(EXE)
endif

# Rule for debugging:   make print-VAR_NAME
print-%: ; $(info $* = $($*))

SHELL=/bin/bash

# COLORS #
_RED		=	\e[31m
_GREEN		=	\e[32m
_YELLOW		=	\e[33m
_BLUE		=	\e[34m
_END		=	\e[0m

# COMPILATION #
CC_FLAGS	=	-Wall -Wextra -Werror
NASM_FLAGS	=	-f elf64

# DIRECTORIES #
DIR_HEADERS		=	./includes/
DIR_SRCS		=	./srcs/
DIR_OBJS		=	./compiled_srcs/
DIR_OBJS_ASM	=	./compiled_srcs/

# FILES #
SRCS			=	famine.c \
					elf.c \
					padding.c \
					utils.c \
					debug.c
SRCS_ASM		=	inject.s


# CMDS #
INJECT		=	readelf -x .text $(DIR_OBJS)$(basename $(SRCS_ASM)) | awk '{if(NR>2)print}' | sed -e '$$d' | sed 's/  //' | cut -f 2- -d ' ' | cut -d ' ' -f 1,2,3,4 | sed 's/ //g' | sed 's/\n//g' | tr -d '\n' | sed 's/../\\\\x&/g'

SIZE_INJECT =	(echo -n "("; (wc -c <<< $(shell $(INJECT))) | xargs echo -n; echo " - 1) / 4") | bc


# COMPILED_SOURCES #
OBJS 		=	$(SRCS:%.c=$(DIR_OBJS)%.o)
OBJS_ASM	=	$(SRCS_ASM:%.s=$(DIR_OBJS_ASM)%.o)
NAME 		=	Famine

## RULES ##
all:			$(NAME)

debug:			CC_FLAGS += -g3 -fsanitize=address -DDEBUG=1
debug:			clean all

# VARIABLES RULES #

$(NAME):		$(OBJS_ASM) $(OBJS)
				@printf "\033[2K\r$(_BLUE) All files compiled into '$(DIR_OBJS)'. $(_END)✅\n"
				@gcc $(CC_FLAGS) -I $(DIR_HEADERS) $(OBJS) -o $(NAME)
				@printf "\033[2K\r$(_GREEN) Executable '$(NAME)' created. $(_END)✅\n"

# COMPILED_SOURCES RULES #
$(OBJS):		| $(DIR_OBJS)

$(OBJS_ASM):	| $(DIR_OBJS_ASM)

$(DIR_OBJS)%.o: $(DIR_SRCS)%.c
				@printf "\033[2K\r $(_YELLOW)Compiling $< $(_END)⌛ "
				@gcc $(CC_FLAGS) -D INJECT=\"$(shell $(INJECT))\" -D INJECT_SIZE=$(shell $(SIZE_INJECT)) -I $(DIR_HEADERS) -c $< -o $@

$(DIR_OBJS_ASM)%.o: $(DIR_SRCS)%.s
				@printf "\033[2K\r $(_YELLOW)Compiling $< $(_END)⌛ "
				@nasm $(NASM_FLAGS) -o $@ $<
				@ld $@ -o $(basename $@)

$(DIR_OBJS):
				@mkdir -p $(DIR_OBJS)

# MANDATORY PART #
clean:
				@rm -rf $(DIR_OBJS)
				@printf "\033[2K\r$(_RED) '"$(DIR_OBJS)"' has been deleted. $(_END)🗑️\n"

fclean:			clean
				@rm -rf $(NAME)
				@printf "\033[2K\r$(_RED) '"$(NAME)"' has been deleted. $(_END)🗑️\n"

re:				fclean all

# PHONY #

.PHONY:			all debug clean fclean re

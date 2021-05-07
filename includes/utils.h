#ifndef UTILS_H
# define UTILS_H

void	*ft_memchr(const void *s, int c, size_t n);
int		ft_memcmp(const void *s1, const void *s2, size_t n);
void	*ft_memcpy(void *dst, const void *src, size_t n);
void	*ft_memmem(const void *l, size_t l_len, const void *s, size_t s_len);
void	*ft_memset(void *b, int c, size_t len);
void	ft_puthexa(unsigned long n);
void	ft_putnbr(int n);
void	ft_putstr(char *str);
char	*ft_strcat(char *dst, const char *src);
int		ft_strcmp(const char *s1, const char *s2);
char	*ft_strcpy(char *dst, const char *src);
size_t	ft_strlen(const char *s);

#endif

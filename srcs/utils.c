#include "famine.h"

void	*ft_memchr(const void *s, int c, size_t n)
{
	unsigned char *pt;

	pt = (unsigned char *)s;
	while (n--)
		if (*pt == (unsigned char)c)
			return (pt);
		else
			pt++;
	return (NULL);
}

int		ft_memcmp(const void *s1, const void *s2, size_t n)
{
	unsigned char *pt_s1;
	unsigned char *pt_s2;

	pt_s1 = (unsigned char *)s1;
	pt_s2 = (unsigned char *)s2;
	while (n--)
		if (*pt_s1++ != *pt_s2++)
			return ((pt_s1 - 1) - (pt_s2 - 1));
	return (0);
}

void		*ft_memcpy(void *dst, const void *src, size_t n)
{
	unsigned char	*pt_src;
	unsigned char	*pt_dst;

	pt_src = (unsigned char *)src;
	pt_dst = (unsigned char *)dst;
	while (n--)
		*pt_dst++ = *pt_src++;
	return (dst);
}

void	*ft_memmem(const void *l, size_t l_len, const void *s, size_t s_len)
{
	register char *cur, *last;
	const char *cl = (const char *)l;
	const char *cs = (const char *)s;

	if (l_len == 0 || s_len == 0)
		return NULL;
	if (l_len < s_len)
		return NULL;
	if (s_len == 1)
		return ft_memchr(l, (int)*cs, l_len);
	last = (char *)cl + l_len - s_len;
	for (cur = (char *)cl; cur <= last; cur++)
		if (cur[0] == cs[0] && ft_memcmp(cur, cs, s_len) == 0)
			return cur;
	return (NULL);
}

void		*ft_memset(void *b, int c, size_t len)
{
	unsigned char	*pt;

	pt = (unsigned char *)b;
	while (len--)
		*pt++ = (unsigned char)c;
	return (b);
}

void	ft_puthexa(unsigned long n)
{
	int				i;
	char			str[32];
	unsigned long	nnbr;
	int				size;

	size = 0;
	nnbr = n;
	while (n)
	{
		n /= 16;
        size++;
	}
	if (!size)
		str[size++] = '0';
	str[size] = '\0';
	i = size;
	n = nnbr;
	while (i--)
	{
		if (nnbr % 16 < 10)
			str[i] = (nnbr % 16) + 48;
		else
			str[i] = (nnbr % 16) + (97 - 10);
		nnbr /= 16;
	}
	syscall_write(STDOUT_FILENO, str, size);
}

void	ft_putnbr(int n)
{
	char c;
	long nnbr;

	nnbr = n;
	if (nnbr < 0)
	{
		syscall_write(STDOUT_FILENO, "-", 1);
		nnbr *= -1;
	}
	if (nnbr != 0)
	{
		if (nnbr / 10 > 0)
			ft_putnbr(nnbr / 10);
		c = nnbr % 10 + 48;
		syscall_write(STDOUT_FILENO, &c, 1);
	}
	if (n == 0)
		syscall_write(STDOUT_FILENO, "0", 1);
}

void	ft_putstr(char *str)
{
	syscall_write(STDOUT_FILENO, str, ft_strlen(str));
}

char	*ft_strcpy(char *dst, const char *src)
{
	int		i;

	i = -1;
	while (src[++i])
		dst[i] = src[i];
	dst[i] = '\0';
	return (dst);
}

char	*ft_strcat(char *dst, const char *src)
{
	size_t		i;
	size_t		j;

	i = 0;
	while (dst[i])
		i++;
	j = 0;
	while (src[j])
		dst[i++] = src[j++];
	dst[i] = '\0';
	return (dst);
}

size_t		ft_strlen(const char *s)
{
	const char *ptr;

	ptr = s;
	while (*ptr)
		++ptr;
	return (ptr - s);
}

int			ft_strcmp(const char *s1, const char *s2)
{
	int i;

	i = 0;
	while (s1[i] && s2[i] && s1[i] == s2[i])
		i++;
	return ((unsigned char)s1[i] - (unsigned char)s2[i]);
}

extern int printf (char const *,...);

// Multiple function definitions with the same string
void FUNC_NAME (void) { printf ("shared\n"); }

#ifdef DEFINE_OTHER_FUNC
void other_func (void) { printf ("unique\n"); }
#endif

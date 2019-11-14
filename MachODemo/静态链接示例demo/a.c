//a.c
#include <stdio.h>
extern int global_var;
void reset(int num);
int main() {
    reset(global_var+1);
}

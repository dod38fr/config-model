//    Copyright (c) 2008 Dominique Dumont.
// 
//    This library is free software; you can redistribute it and/or
//    modify it under the terms of the GNU Lesser Public License as
//    published by the Free Software Foundation; either version 2.1 of
//    the License, or (at your option) any later version.
// 
//    Config-Model is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//    Lesser Public License for more details.
// 
//    You should have received a copy of the GNU Lesser Public License
//    along with Config-Model; if not, write to the Free Software
//    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
//    02110-1301 USA

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newCONSTSUB
#include "ppport.h"

#include </usr/local/include/augeas.h>

typedef augeas Config_Augeas ;
typedef PerlIO *        OutputStream;

MODULE = Config::Augeas PACKAGE = Config::Augeas PREFIX = aug_

 # See http://blogs.sun.com/akolb/entry/pitfals_of_the_perl_xs
 # 
 # Define any constants that need to be exported.  By doing it this way
 # we can avoid the overhead of using the DynaLoader package, and in
 # addition constants defined using this mechanism are eligible for
 # inlining by the perl interpreter at compile time.

BOOT:
  {
    HV *stash;
    stash = gv_stashpv("Config::Augeas", TRUE);
    newCONSTSUB(stash, "AUG_NONE",         newSViv(AUG_NONE));
    newCONSTSUB(stash, "AUG_SAVE_BACKUP",  newSViv(AUG_SAVE_BACKUP));
    newCONSTSUB(stash, "AUG_SAVE_NEWFILE", newSViv(AUG_SAVE_NEWFILE));
    newCONSTSUB(stash, "AUG_TYPE_CHECK",   newSViv(AUG_TYPE_CHECK));
  }

Config_Augeas*
aug_init(char* root = NULL ,char* loadpath = NULL ,unsigned int flags = 0)


MODULE = Config::Augeas PACKAGE = Config::AugeasPtr PREFIX = aug_

void
aug_DESTROY(Config_Augeas* aug)
    CODE:
      //printf("destroying aug object\n");
      aug_close(aug);

int
aug_get(IN Config_Augeas* aug, IN char* path, OUTLIST const char* value)

int
aug_set(Config_Augeas* aug, const char* path, char* c_value)

int 
aug_insert(Config_Augeas* aug, const char* path, const char* label, int before)

int 
aug_rm(Config_Augeas *aug, const char *path);

void
aug_match(Config_Augeas *aug, const char *pattern);
    PPCODE:
        char**  matches;
    
        int cnt = aug_match(aug, pattern, &matches);

        if (cnt == -1) {
            return ;
        }

        // printf("match: Pattern %s matches %d times\n", pattern, cnt);
    
        int i ;
        for (i=0; i < cnt; i++) {
            XPUSHs(sv_2mortal(newSVpv(matches[i], 0)));
            free((void*) matches[i]);
        }
        free(matches);

int
aug_count_match(Config_Augeas *aug, const char *pattern);
    CODE:
        RETVAL = aug_match(aug, pattern,NULL);
    OUTPUT:
        RETVAL


int 
aug_save(Config_Augeas *aug);

 # See example 9 in perlxstut man page
int
aug_print(Config_Augeas *aug, OutputStream stream, const char* path);
    CODE:
        FILE *fp = PerlIO_findFILE(stream);
        if (fp != (FILE*) 0) {
             RETVAL = aug_print(aug, fp, path);
         } else {
             RETVAL = -1;
         }
    OUTPUT:
        RETVAL

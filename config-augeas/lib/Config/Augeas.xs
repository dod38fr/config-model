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

#include <string.h>
#include <stdio.h>
#include <augeas.h>

typedef augeas   Config_Augeas ;
typedef PerlIO*  OutputStream;

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
    newCONSTSUB(stash, "AUG_NO_STDINC",    newSViv(AUG_NO_STDINC));
    newCONSTSUB(stash, "AUG_SAVE_NOOP",    newSViv(AUG_SAVE_NOOP));
    newCONSTSUB(stash, "AUG_NO_LOAD",      newSViv(AUG_NO_LOAD));
  }

Config_Augeas*
aug_init(root = NULL ,loadpath = NULL ,flags = 0)
      char* root 
      char* loadpath
      unsigned int flags


MODULE = Config::Augeas PACKAGE = Config::AugeasPtr PREFIX = aug_

void
aug_DESTROY(aug)
      Config_Augeas* aug
    CODE:
      //printf("destroying aug object\n");
      aug_close(aug);

int
aug_defvar(aug, name, expr)
      Config_Augeas* aug
      const char* name
      const char* expr

 # returns an array ( return value, created ) 
void
aug_defnode(aug, name, expr, value)
      Config_Augeas* aug
      const char* name
      const char* expr
      const char* value
    PREINIT:
      int created ;
      int ret ;
    PPCODE:
      created = 1 ;
      ret = aug_defnode(aug, name, expr, value, &created ) ;
      if (ret >= 0 ) {
        XPUSHs(sv_2mortal(newSVnv(ret)));
        XPUSHs(sv_2mortal(newSVnv(created)));
      }

const char*
aug_get(aug, path)
      Config_Augeas* aug
      char* path
    PREINIT:
      int ret ;
    CODE:
      ret = aug_get(aug, path, &RETVAL);
    OUTPUT:
      RETVAL

int
aug_set(aug, path, c_value)
      Config_Augeas* aug
      const char* path
      char* c_value

int 
aug_insert(aug, path, label, before)
      Config_Augeas* aug
      const char* path
      const char* label
      int before

int 
aug_rm(aug, path);
      Config_Augeas *aug
      const char *path

int 
aug_mv(aug, src, dst);
      Config_Augeas *aug
      const char *src
      const char *dst

void
aug_match(aug, pattern);
      Config_Augeas *aug
      const char *pattern
    PREINIT:
        char** matches;
        char** err_matches;
        const char*  err_string ;
        int i ;
        int ret ;
	int cnt;
	char die_msg[1024] ;
	char tmp_msg[128];
    PPCODE:
    
        cnt = aug_match(aug, pattern, &matches);

        if (cnt == -1) {
	   sprintf(die_msg, "aug_match error with pattern '%s':\n",pattern);
    	   cnt = aug_match(aug,"/augeas//error/descendant-or-self::*",&err_matches);
	   for (i=0; i < cnt; i++) {
               ret = aug_get(aug, err_matches[i], &err_string) ;
	       sprintf(tmp_msg,"%s = %s\n", err_matches[i], err_string );
	       if (strlen(die_msg) + strlen(tmp_msg) < 1024 )
	       	       strcat(die_msg,tmp_msg);
	   }
	   croak ("%s",die_msg);
        }

        // printf("match: Pattern %s matches %d times\n", pattern, cnt);
    
        for (i=0; i < cnt; i++) {
            XPUSHs(sv_2mortal(newSVpv(matches[i], 0)));
            free((void*) matches[i]);
        }
        free(matches);

int
aug_count_match(aug, pattern);
      Config_Augeas *aug
      const char *pattern
    CODE:
        RETVAL = aug_match(aug, pattern,NULL);
    OUTPUT:
        RETVAL


int 
aug_save( aug );
      Config_Augeas *aug

 # See example 9 in perlxstut man page
int
aug_print(aug, stream, path);
        Config_Augeas *aug
	OutputStream stream
	const char* path
    PREINIT:
        FILE *fp ;
    CODE:
        fp = PerlIO_findFILE(stream);
        if (fp != (FILE*) 0) {
             RETVAL = aug_print(aug, fp, path);
         } else {
             RETVAL = -1;
         }
    OUTPUT:
        RETVAL

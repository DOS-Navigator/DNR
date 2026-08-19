{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator  Version 1.51  Copyright (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on TinyWeb Server by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}

unit DnStrings;
{$V-} { relaxed var-string checks: DN 1.51's original build setting, lost with its TURBO.CFG; see TOOLCHAIN.md }

{-----------------------------------------------------}
{ This module is based on Turbo Vision Strings Unit   }
{ Copyright (c) 1990 by Borland International         }
{-----------------------------------------------------}


{$S-}

interface

{ StrLen returns the number of characters in Str, not counting  }
{ the null terminator.                                          }

function StrLen(Str: PChar): Word;

{ StrEnd returns a pointer to the null character that           }
{ terminates Str.                                               }

function StrEnd(Str: PChar): PChar;

{ StrMove copies exactly Count characters from Source to Dest   }
{ and returns Dest. Source and Dest may overlap.                }

function StrMove(Dest, Source: PChar; Count: Word): PChar;

{ StrCopy copies Source to Dest and returns Dest.               }

function StrCopy(Dest, Source: PChar): PChar;

{ StrECopy copies Source to Dest and returns StrEnd(Dest).      }

function StrECopy(Dest, Source: PChar): PChar;

{ StrLCopy copies at most MaxLen characters from Source to Dest }
{ and returns Dest.                                             }

function StrLCopy(Dest, Source: PChar; MaxLen: Word): PChar;

{ StrPCopy copies the Pascal style string Source into Dest and  }
{ returns Dest.                                                 }

function StrPCopy(Dest: PChar; Source: String): PChar;

{ StrCat appends a copy of Source to the end of Dest and        }
{ returns Dest.                                                 }

function StrCat(Dest, Source: PChar): PChar;

{ StrLCat appends at most MaxLen - StrLen(Dest) characters from }
{ Source to the end of Dest, and returns Dest.                  }

function StrLCat(Dest, Source: PChar; MaxLen: Word): PChar;

{ StrComp compares Str1 to Str2. The return value is less than  }
{ 0 if Str1 < Str2, 0 if Str1 = Str2, or greater than 0 if      }
{ Str1 > Str2.                                                  }

function StrComp(Str1, Str2: PChar): Integer;

{ StrIComp compares Str1 to Str2, without case sensitivity. The }
{ return value is the same as StrComp.                          }

function StrIComp(Str1, Str2: PChar): Integer;

{ StrLComp compares Str1 to Str2, for a maximum length of       }
{ MaxLen characters. The return value is the same as StrComp.   }

function StrLComp(Str1, Str2: PChar; MaxLen: Word): Integer;

{ StrLIComp compares Str1 to Str2, for a maximum length of      }
{ MaxLen characters, without case sensitivity. The return value }
{ is the same as StrComp.                                       }

function StrLIComp(Str1, Str2: PChar; MaxLen: Word): Integer;

{ StrScan returns a pointer to the first occurrence of Chr in   }
{ Str. If Chr does not occur in Str, StrScan returns NIL. The   }
{ null terminator is considered to be part of the string.       }

function StrScan(Str: PChar; Chr: Char): PChar;

{ StrRScan returns a pointer to the last occurrence of Chr in   }
{ Str. If Chr does not occur in Str, StrRScan returns NIL. The  }
{ null terminator is considered to be part of the string.       }

function StrRScan(Str: PChar; Chr: Char): PChar;

{ StrPos returns a pointer to the first occurrence of Str2 in   }
{ Str1. If Str2 does not occur in Str1, StrPos returns NIL.     }

function StrPos(Str1, Str2: PChar): PChar;

{ StrUpper converts Str to upper case and returns Str.          }

function StrUpper(Str: PChar): PChar;

{ StrLower converts Str to lower case and returns Str.          }

function StrLower(Str: PChar): PChar;

{ StrPas converts Str to a Pascal style string.                 }

function StrPas(Str: PChar): String;

{ StrNew allocates a copy of Str on the heap. If Str is NIL or  }
{ points to an empty string, StrNew returns NIL and doesn't     }
{ allocate any heap space. Otherwise, StrNew makes a duplicate  }
{ of Str, obtaining space with a call to the GetMem standard    }
{ procedure, and returns a pointer to the duplicated string.    }
{ The allocated space is StrLen(Str) + 1 bytes long.            }

function StrNew(Str: PChar): PChar;

{ StrDispose disposes a string that was previously allocated    }
{ with StrNew. If Str is NIL, StrDispose does nothing.          }

procedure StrDispose(Str: PChar);

implementation

{ This unit's whole interface is the classic Borland Turbo Vision Strings
  unit (see header above); FPC's own RTL "strings" unit already implements
  the identical, TP7-compatible API portably across every target. Rather
  than hand-porting ~20 16-bit-assembler routines (LES/LDS far-pointer
  tricks meaningless on a flat 32-bit target), this unit forwards to it. }

uses
  Strings;

function StrLen(Str: PChar): Word;
begin
  StrLen := Word(Strings.StrLen(Str));
end;

function StrEnd(Str: PChar): PChar;
begin
  StrEnd := Strings.StrEnd(Str);
end;

function StrMove(Dest, Source: PChar; Count: Word): PChar;
begin
  StrMove := Strings.StrMove(Dest, Source, Count);
end;

function StrCopy(Dest, Source: PChar): PChar;
begin
  StrCopy := Strings.StrCopy(Dest, Source);
end;

function StrECopy(Dest, Source: PChar): PChar;
begin
  StrECopy := Strings.StrECopy(Dest, Source);
end;

function StrLCopy(Dest, Source: PChar; MaxLen: Word): PChar;
begin
  StrLCopy := Strings.StrLCopy(Dest, Source, MaxLen);
end;

function StrPCopy(Dest: PChar; Source: String): PChar;
begin
  StrPCopy := Strings.StrPCopy(Dest, Source);
end;

function StrCat(Dest, Source: PChar): PChar;
begin
  StrCat := Strings.StrCat(Dest, Source);
end;

function StrLCat(Dest, Source: PChar; MaxLen: Word): PChar;
begin
  StrLCat := Strings.StrLCat(Dest, Source, MaxLen);
end;

function StrComp(Str1, Str2: PChar): Integer;
begin
  StrComp := Strings.StrComp(Str1, Str2);
end;

function StrIComp(Str1, Str2: PChar): Integer;
begin
  StrIComp := Strings.StrIComp(Str1, Str2);
end;

function StrLComp(Str1, Str2: PChar; MaxLen: Word): Integer;
begin
  StrLComp := Strings.StrLComp(Str1, Str2, MaxLen);
end;

function StrLIComp(Str1, Str2: PChar; MaxLen: Word): Integer;
begin
  StrLIComp := Strings.StrLIComp(Str1, Str2, MaxLen);
end;

function StrScan(Str: PChar; Chr: Char): PChar;
begin
  StrScan := Strings.StrScan(Str, Chr);
end;

function StrRScan(Str: PChar; Chr: Char): PChar;
begin
  StrRScan := Strings.StrRScan(Str, Chr);
end;

function StrPos(Str1, Str2: PChar): PChar;
begin
  StrPos := Strings.StrPos(Str1, Str2);
end;

function StrUpper(Str: PChar): PChar;
begin
  StrUpper := Strings.StrUpper(Str);
end;

function StrLower(Str: PChar): PChar;
begin
  StrLower := Strings.StrLower(Str);
end;

function StrPas(Str: PChar): String;
begin
  StrPas := Strings.StrPas(Str);
end;

function StrNew(Str: PChar): PChar;
begin
  StrNew := Strings.StrNew(Str);
end;

procedure StrDispose(Str: PChar);
begin
  Strings.StrDispose(Str);
end;

end.

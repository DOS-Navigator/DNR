(* RUNCMD.INC - compile-clean scaffolding, 2026-08-19. NOT the original.

   The original file is missing from this repository (see TOOLCHAIN.md).
   It carried the bodies of DNUTIL's command-execution layer:

       ExecString  SearchExt  ExecExtFile  ExecFile  SaveDsk

   This scaffolding exists so the dependency graph can compile - DNUTIL
   gates the entire UI layer through VIEWS' implementation uses-chain.
   It is NOT silent: every routine raises RunError(199) the moment it is
   called, so a running binary cannot appear to work while command
   execution is missing. Do not ship a build that can reach these.

   Recovery: an original DN 1.51 source distribution, or a back-port of
   dnexec.pas (769 lines, 32-bit) from the DN Open Source / NDN tree,
   which contains all four routines' descendants. *)

procedure ExecString(S: Str128);
begin
  RunError(199);   { RUNCMD.INC scaffolding: ExecString not recovered }
end;

function SearchExt(Name: NameStr; Ext: ExtStr; var HS: String): Boolean;
begin
  SearchExt := False;
  RunError(199);   { RUNCMD.INC scaffolding: SearchExt not recovered }
end;

function ExecExtFile(const ExtFName, FName: PathStr; SIdx: TStrIdx): Boolean;
begin
  ExecExtFile := False;
  RunError(199);   { RUNCMD.INC scaffolding: ExecExtFile not recovered }
end;

procedure ExecFile(Name: PathStr);
begin
  RunError(199);   { RUNCMD.INC scaffolding: ExecFile not recovered }
end;

procedure SaveDsk;
{ Saves screen/video state before shelling to DOS; called immediately
  before ExecString/ExecFile at every site in DNUTIL. }
begin
  RunError(199);   { RUNCMD.INC scaffolding: SaveDsk not recovered }
end;

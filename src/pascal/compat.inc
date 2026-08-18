{$MODE FPC}
{$MODESWITCH RESULT+}  // `Result` is NOT available in {$MODE FPC}; it is only
                       // on by default in OBJFPC/DELPHI. Without this the
                       // MODERN blocks fail with "Identifier not found Result".
{$PACKRECORDS 1}  // Maintain DOS-like structure packing
{$DEFINE MODERN}   // Flag for modern compilation

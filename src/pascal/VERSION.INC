{ VERSION.INC - generated content, reconstructed 2026-08-18.

  This file is normally PRODUCED by VERSION.PAS, which is a standalone
  generator program (not a unit) in this same directory. Its tail writes
  exactly the four lines below:

      Writeln(F,'  Const');
      Writeln(F,'     VersionName =''',VersionName,''';');
      Writeln(F,'     VersionDate =''',VersionDate,''';');
      Writeln(F,'     VersionWord = $', Hex4(VersionWord) , ';');

  and VERSION.PAS itself declares:

      VersionName = '1.51';
      VersionDate = 'April 19, 1999';
      VersionWord = $100 + 51;          { = 307 = $0133 }

  So the values here are authoritative for DN 1.51, taken from this
  repository's own source rather than from any external fork.

  Consumers: DN.PAS, DNUTIL.PAS, DRIVERS.PAS, GAUGES.PAS.
  VersionWord is assigned to a plain `word` (GAUGES.PAS: Vversion). }

  Const
     VersionName ='1.51';
     VersionDate ='April 19, 1999';
     VersionWord = $0133;

program RetrSyscall;

uses windows,sysutils,debug; //,JwaWinBase;

var
  ssn:nativeuint;
  ptr:pointer;
  h1:pointer;
  lib:hmodule=0;

  procedure log(msg:string);
begin
writeln(msg);
end;



begin

  if paramcount=0 then exit;
  //SetErrorMode(0);
  //SetUnhandledExceptionFilter(nil);
  //SetUnhandledExceptionFilter( LPTOP_LEVEL_EXCEPTION_FILTER(@OneShotHardwareBreakpointHandler));
  h1:=AddVectoredExceptionHandler(1, LPTOP_LEVEL_EXCEPTION_FILTER(@OneShotHardwareBreakpointHandler));

  lib:=GetModuleHandleA( 'NTDLL.dll' );
  //ptr:=GetProcAddress( lib, 'NtOpenProcess' );
  //writeln('NtOpenProcess:'+inttohex(nativeuint(ptr),8));
  if GetProcAddress( lib, pchar(paramstr(1)))=nil then exit;
  ssn := RetrieveSyscall( GetProcAddress( lib, pchar(paramstr(1)) ) );

  writeln( paramstr(1) +' SSN : '+inttohex(ssn,8) );

  //test
  //RaiseException(STATUS_SINGLE_STEP, 0, 0, nil);

  RemoveVectoredExceptionHandler(h1);

  //0xC0000005 STATUS_ACCESS_VIOLATION
  //0xC0000030 STATUS_INVALID_PARAMETER_MIX
end.


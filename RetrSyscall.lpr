program RetrSyscall;

uses windows,sysutils,debug; //,JwaWinBase;

var
  ssn:nativeuint;
  ptr:pointer;
  stop:boolean=false;
  tid:dword;
  h1:pointer;

  procedure log(msg:string);
begin
writeln(msg);
end;



begin


  //SetErrorMode(0);
  //SetUnhandledExceptionFilter(nil);
  //SetUnhandledExceptionFilter( LPTOP_LEVEL_EXCEPTION_FILTER(@OneShotHardwareBreakpointHandler));
  h1:=AddVectoredExceptionHandler(1, LPTOP_LEVEL_EXCEPTION_FILTER(@OneShotHardwareBreakpointHandler));


  ptr:=GetProcAddress( GetModuleHandleA( 'NTDLL.dll' ), 'NtOpenProcess' );
  writeln('NtOpenProcess:'+inttohex(nativeuint(ptr),8));
  ssn := RetrieveSyscall( ptr );
  //ssn := RetrieveSyscall( GetProcAddress( GetModuleHandleA( 'NTDLL.dll' ), 'NtGetContextThread' ) );

  writeln( 'NtOpenProcess SSN : '+inttohex(ssn,8) );

  //test
  //RaiseException(STATUS_SINGLE_STEP, 0, 0, nil);

  RemoveVectoredExceptionHandler(h1);

  //0xC0000005 STATUS_ACCESS_VIOLATION
  //0xC0000030 STATUS_INVALID_PARAMETER_MIX
end.


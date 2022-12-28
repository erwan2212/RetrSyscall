unit debug;

//{$mode objfpc}{$H+}

interface

uses
   windows,SysUtils; //,ubits;


type
  PTOP_LEVEL_EXCEPTION_FILTER = function(ExceptionInfo: PEXCEPTION_POINTERS): LONG; stdcall;
  LPTOP_LEVEL_EXCEPTION_FILTER = PTOP_LEVEL_EXCEPTION_FILTER;
  TTopLevelExceptionFilter = PTOP_LEVEL_EXCEPTION_FILTER;
  PVECTORED_EXCEPTION_HANDLER=PTOP_LEVEL_EXCEPTION_FILTER;

procedure SetOneshotHardwareBreakpoint( address_ : LPVOID);
function FindSyscallAddress( function_:LPVOID ):lpvoid;
function OneShotHardwareBreakpointHandler( ExceptionInfo: PEXCEPTION_POINTERS ):longint;stdcall;
function RetrieveSyscall(  FunctionAddress:PVOID ):nativeuint;

//from jwawinbase
function SetUnhandledExceptionFilter(lpTopLevelExceptionFilter: LPTOP_LEVEL_EXCEPTION_FILTER): LPTOP_LEVEL_EXCEPTION_FILTER; stdcall; external 'kernel32.dll';
function AddVectoredExceptionHandler(FirstHandler: ULONG;VectoredHandler: PVECTORED_EXCEPTION_HANDLER): PVOID; stdcall; external 'kernel32.dll';
function RemoveVectoredExceptionHandler(VectoredHandlerHandle: PVOID): ULONG; stdcall; external 'kernel32.dll';

implementation

type NTSTATUS = ULONG;

function NtGetContextThread(pThread:handle; pContext:PCONTEXT):NTSTATUS; stdcall;external 'ntdll.dll';
function NtSetContextThread(pThread:handle; Context:PCONTEXT):NTSTATUS; stdcall;external 'ntdll.dll';

procedure log(msg:string);
begin
     writeln(msg);
end;

function AllocMemAlign(const ASize, AAlign: Cardinal; out AHolder: Pointer): Pointer;
var
  Size: Cardinal;
  Shift: NativeUInt;
begin
  if AAlign <= 1 then
  begin
    AHolder := AllocMem(ASize);
    Result := AHolder;
    Exit;
  end;

  if ASize = 0 then
  begin
    AHolder := nil;
    Result := nil;
    Exit;
  end;

  Size := ASize + AAlign - 1;

  AHolder := AllocMem(Size);

  Shift := NativeUInt(AHolder) mod AAlign;
  if Shift = 0 then
    Result := AHolder
  else
    Result := Pointer(NativeUInt(AHolder) + (AAlign - Shift));
end;

function RetrieveSyscall(  FunctionAddress:PVOID ):nativeuint;
type
  fn=function():dword;stdcall;
var
ssn:dword;
ReturnNtStatus:dword;
begin
        log('**** RetrieveSyscall ****');
        log('FunctionAddress:'+inttohex(nativeuint(FunctionAddress),8));
        //setting local hwbp
	SetOneshotHardwareBreakpoint( FindSyscallAddress( FunctionAddress ) );
        //calling our function
        ReturnNtStatus:=fn(FunctionAddress)();
	ssn := ReturnNtStatus;

	result:= ssn;
end;



//https://www.tutorialspoint.com/cprogramming/c_operators.htm
function OneShotHardwareBreakpointHandler( ExceptionInfo:PEXCEPTION_POINTERS ):longint;stdcall;
begin
log('!!!! OneShotHardwareBreakpointHandler !!!!');
log('ExceptionCode:'+inttohex(ExceptionInfo^.ExceptionRecord^.ExceptionCode,8));
log('Dr7:'+inttohex(ExceptionInfo^.ContextRecord^.Dr7,8));
log('Dr0:'+inttohex(ExceptionInfo^.ContextRecord^.Dr0,8));
log('Rip:'+inttohex(ExceptionInfo^.ContextRecord^.Rip,8));
	if( ExceptionInfo^.ExceptionRecord^.ExceptionCode = STATUS_SINGLE_STEP ) then
	begin
        log('...STATUS_SINGLE_STEP...');
		if( ExceptionInfo^.ContextRecord^.Dr7 and 1=1 ) then //to be checked
                begin
                log('...Dr7 and 1=1...');
                        // if the ExceptionInfo->ContextRecord->Rip == ExceptionInfo->ContextRecord->Dr0
			// then we are at the one shot breakpoint address
			if( ExceptionInfo^.ContextRecord^.Rip= ExceptionInfo^.ContextRecord^.Dr0 ) then
                        begin
                             log('...Rip=Dr0...');
			     ExceptionInfo^.ContextRecord^.Dr0 := 0;

			     ExceptionInfo^.ContextRecord^.Rip :=ExceptionInfo^.ContextRecord^.Rip+ 2;
			     // ExceptionInfo->ContextRecord->Rax should hold the syscall number
			     result:= EXCEPTION_CONTINUE_EXECUTION;
                             exit; //as opposed to c++, result does not exit the current method
			end;
		end;
	end;
	result:= EXCEPTION_CONTINUE_SEARCH;
end;

procedure SetOneshotHardwareBreakpoint( address_ : LPVOID);
var
  context : PCONTEXT;
  Storage: Pointer;
begin
  log('**** SetOneshotHardwareBreakpoint ****');
  log('address_:'+inttohex(nativeuint(address_) ,sizeof(dword64)));
  //fillchar(CONTEXT,sizeof(TCONTEXT),0);
  {$IFDEF win64}CONTEXT := AllocMemAlign(SizeOf(TContext), 16, Storage);{$endif}
  {$IFDEF win32}CONTEXT := AllocMemAlign(SizeOf(TContext), 0, Storage);{$endif}

  context^.ContextFlags := CONTEXT_DEBUG_REGISTERS;
  if NtGetContextThread( GetCurrentThread(), context )<>0
     then log('GetThreadContext failed:'+inttostr(getlasterror));
     //else log('GetThreadContext ok');
  context^.Dr0 := dword64(address_); //Debug Address Registers or Address-Breakpoint Registers
  context^.Dr6 := 0;  //Debug Status Register
  //context^.Dr7 := 0;  //Debug Control Register
  //The first 8 bits control if a specific hardware breakpoint is enabled
  //Even bits (0, 2, 4 and 6), called L0 - L3, enable the breakpoint locally, meaning it will only trigger when the breakpoint exception is detected in the current task.
  //The uneven bits (1, 3, 5, 7), called G0 - G3, enable the breakpoint globally, meaning it will trigger when the breakpoint exception is detected in any task
  //The bits do not get cleared when it is enabled globally
  {context.Dr7 := (context.Dr7 and ~(((1  shl  2) - 1)  shl  16)) or (0  shl  16);
  context.Dr7 := (context.Dr7 and ~(((1  shl  2) - 1)  shl  18)) or (0  shl  18);
  context.Dr7 := (context.Dr7 and ~(((1  shl  1) - 1)  shl  0)) or (1  shl  0);
  }
  //? context.Dr7 = 1 << 0;  = Set a local 1-byte execution hardware breakpoint ?
  {
  context.Dr7 |= (3 << 16); //set bits 16-17 to 1 - break read/write
  context.Dr7 |= (3 << 18); //set bits 18-19 to 1 - size = 4  //SIZE_2 ~0x01 SIZE_8 ~0x07
  context.Dr7 |= 0x101; //enable local hardware breakpoint on dr0
  }
  //or context.Dr7 |= (1 << 0);


  //context^.Dr7 := context^.Dr7 or (3 shl 16);
  //context^.Dr7 := context^.Dr7 or (3 shl 18);
  //context^.Dr7 := context^.Dr7 or (1 shl 0);

  //context^.Dr7 :=$101; //works too

  context^.Dr7 :=1; //works too

  log('Dr0:'+inttohex(context^.Dr0 ,sizeof(dword64)));
  log('Dr7:'+inttohex(context^.Dr7 ,sizeof(dword64)));

  context^.ContextFlags := CONTEXT_DEBUG_REGISTERS;
  if NtSetContextThread( GetCurrentThread(), context )<>0
     then log('SetThreadContext failed:'+inttostr(getlasterror));
     //else log('SetThreadContext ok');

     exit; //or not? depends on dr7?
     //as opposed to c++, wierdly enough, requesting registers again triggers the HWBP
     context^.ContextFlags := CONTEXT_DEBUG_REGISTERS;
     if NtGetContextThread( GetCurrentThread(), context )<>0
        then log('GetThreadContext failed:'+inttostr(getlasterror));
     log('Dr0:'+inttohex(context^.Dr0 ,sizeof(dword64)));
     log('Dr7:'+inttohex(context^.Dr7 ,sizeof(dword64)));

end;

/// + 0x12 generally
function FindSyscallAddress( function_:LPVOID ):lpvoid;
var
  	stub:array[0..1] of byte = ($0F, $05) ;
        i:ulong;
begin
        log('**** FindSyscallAddress ****');
        log('function_:'+inttohex(nativeuint(function_),8));
       	result:= nil;
	for i := 0 to 24 do
	begin
                //log(inttohex(pbyte(LPVOID(nativeuint(function_) + i))^,2));
                if comparemem( LPVOID(nativeuint(function_) + i),@stub[0],2)=true then
                begin
			result:= LPVOID(nativeuint(function_) + i);break;
		end;
	end;
end;

end.


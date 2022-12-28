//from https://github.com/project-jedi/jcl/blob/master/jcl/source/common/JclLogic.pas
unit Ulogic;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TBitRange = Byte;

implementation

const
  BitsPerNibble   = 4;
    BitsPerByte     = 8;
    BitsPerShortint = SizeOf(Shortint) * BitsPerByte;
    BitsPerSmallint = SizeOf(Smallint) * BitsPerByte;
    BitsPerWord     = SizeOf(Word) * BitsPerByte;
    BitsPerInteger  = SizeOf(Integer) * BitsPerByte;
    BitsPerCardinal = SizeOf(Cardinal) * BitsPerByte;
    BitsPerInt64    = SizeOf(Int64) * BitsPerByte;

function SetBit(const Value: Byte; const Bit: TBitRange): Byte; assembler;
asm
  // 32 --> AL Value
  //        DL Bit
  //    <-- AL Result
  // 64 --> CL Value
  //        DL Bit
  //    <-- AL Result
  AND    EDX, BitsPerByte - 1   // modulo BitsPerByte
  {$IFDEF CPU64}
  MOVZX  EAX, CL
  {$ENDIF CPU64}
  BTS    EAX, EDX
end;

function SetBit(const Value: Shortint; const Bit: TBitRange): Shortint; assembler;
asm
  // 32 --> AL Value
  //        DL Bit
  //    <-- AL Result
  // 64 --> CL Value
  //        DL Bit
  //    <-- AL Result
  AND    EDX, BitsPerShortInt - 1   // modulo BitsPerShortInt
  {$IFDEF CPU64}
  MOVZX  EAX, CL
  {$ENDIF CPU64}
  BTS    EAX, EDX
end;

function SetBit(const Value: Smallint; const Bit: TBitRange): Smallint; assembler;
asm
  // 32 --> AX Value
  //        DL Bit
  //    <-- AX Result
  // 64 --> CX Value
  //        DL Bit
  //    <-- AX Result
  AND    EDX, BitsPerSmallInt - 1   // modulo BitsPerSmallInt
  {$IFDEF CPU64}
  MOVZX  EAX, CX
  {$ENDIF CPU64}
  BTS    EAX, EDX
end;

function SetBit(const Value: Word; const Bit: TBitRange): Word; assembler;
asm
  // 32 --> AX Value
  //        DL Bit
  //    <-- AX Result
  // 64 --> CX Value
  //        DL Bit
  //    <-- AX Result
  AND    EDX, BitsPerWord - 1   // modulo BitsPerWord
  {$IFDEF CPU64}
  MOVZX  EAX, CX
  {$ENDIF CPU64}
  BTS    EAX, EDX
end;

function SetBit(const Value: Cardinal; const Bit: TBitRange): Cardinal; assembler;
asm
  // 32 --> EAX Value
  //        DL  Bit
  //    <-- EAX Result
  // 64 --> ECX Value
  //        DL  Bit
  //    <-- EAX Result
  {$IFDEF CPU64}
  MOV    EAX, ECX
  {$ENDIF CPU64}
  BTS    EAX, EDX
end;

function SetBit(const Value: Integer; const Bit: TBitRange): Integer; assembler;
asm
  // 32 --> EAX Value
  //        DL  Bit
  //    <-- EAX Result
  // 64 --> ECX Value
  //        DL  Bit
  //    <-- EAX Result
  {$IFDEF CPU64}
  MOV    EAX, ECX
  {$ENDIF CPU64}
  BTS    EAX, EDX
end;

function SetBit(const Value: Int64; const Bit: TBitRange): Int64; assembler;
{$IFDEF CPU32}
begin
  Result := Value or (Int64(1) shl (Bit and (BitsPerInt64 - 1)));
end;
{$ENDIF CPU32}
{$IFDEF CPU64}
asm
  // --> RCX Value
  //     DL  Bit
  // <-- RAX Result
  MOV    RAX, RCX
  BTS    RAX, RDX
end;
{$ENDIF CPU64}


end.


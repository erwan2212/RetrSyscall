//Bits library

unit ubits;

{
*******************************************************
 * Copyright (C) 2010-2011 Erwan LABALEC erwan2212@gmail.com
 *
 * This file is part of CloneDisk.
 *
 * CloneDisk source code can not be copied and/or distributed without the express
 * permission of Erwan LABALEC
 *******************************************************/
}

interface

function Get_a_Bit(const aValue: Cardinal; const Bit: Byte): Boolean;
function Set_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
function Clear_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
function Enable_a_Bit(const aValue: Cardinal; const Bit: Byte; const Flag: Boolean): Cardinal;

implementation

//get if a particular bit is 1
function Get_a_Bit(const aValue: Cardinal; const Bit: Byte): Boolean;
begin
  Result := (aValue and (1 shl Bit)) <> 0;
end;

//set a particular bit as 1
function Set_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
begin
  Result := aValue or (1 shl Bit);
end;

//set a particular bit as 0
function Clear_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
begin
  Result := aValue and not (1 shl Bit);
end;

//Enable o disable a bit
function Enable_a_Bit(const aValue: Cardinal; const Bit: Byte; const Flag: Boolean): Cardinal;
begin
  Result := (aValue or (1 shl Bit)) xor (Integer(not Flag) shl Bit);
end;

end.

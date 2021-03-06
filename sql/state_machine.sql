/* ======================================================================== */
/* PeopleRelay: state_machine.sql Version: 0.4.3.6                          */
/*                                                                          */
/* Copyright 2017-2018 Aleksei Ilin & Igor Ilin                             */
/*                                                                          */
/* Licensed under the Apache License, Version 2.0 (the "License");          */
/* you may not use this file except in compliance with the License.         */
/* You may obtain a copy of the License at                                  */
/*                                                                          */
/*     http://www.apache.org/licenses/LICENSE-2.0                           */
/*                                                                          */
/* Unless required by applicable law or agreed to in writing, software      */
/* distributed under the License is distributed on an "AS IS" BASIS,        */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. */
/* See the License for the specific language governing permissions and      */
/* limitations under the License.                                           */
/* ======================================================================== */

/*-----------------------------------------------------------------------------------------------*/
set term ^ ;
/*-----------------------------------------------------------------------------------------------*/
/* Check Power-On-Reset */
create procedure P_CheckPOR
as
  declare AR TBoolean;
  declare SD TTimeGap;
  declare TMGap BigInt;
  declare AAt TTimeMark;
  declare RS TUInt;
  declare Acceptor TBoolean;
begin
  execute procedure P_LogMsg(5,0,0,null,'P_CheckPOR',null,'Start',null);

  SD = Gen_Id(P_G$SDU,0);
  select
      Acceptor,
      ((SyncSpan + :SD) * PowerOnReset),
      AutoRegister,
      RegisterSpan,
      AlteredAt
    from P_TParams
    into
      :Acceptor,
      :TMGap,
      :AR,
      :RS,
      :AAt;

  if (AR = 1
    and (AAt is not null
      or (select Result from P_SyncPOR(:TMGap)) = 1
      or (RS > 0 and Mod(Gen_Id(P_G$RTT,0),RS) = 0)
      or (select Result from P_IpOrDBChanged) = 1))
  then
    execute procedure P_Register;

  execute procedure P_LogMsg(5,0,0,null,'P_CheckPOR',null,'Finish',null);
end^
/*-----------------------------------------------------------------------------------------------*/
create procedure P_ClearLogs
as
begin
  execute procedure P_ClearBackLog;
  execute procedure P_ClearMeltingPot;
end^
/*-----------------------------------------------------------------------------------------------*/
create procedure P_Sweep
as
  declare LLS TCount;
begin
  select SweepSpan from P_TParams into :LLS;
  if (LLS > 0) then
  begin
    LLS = Gen_Id(P_G$RTT,0) - LLS;
    delete from P_TBacklog where RT < :LLS;
    delete from P_TMeltingPot where Own = 0 and RT < :LLS;
  end
end^
/*-----------------------------------------------------------------------------------------------*/
set term ; ^
/*-----------------------------------------------------------------------------------------------*/
grant select on P_TParams to procedure P_CheckPOR;
grant execute on procedure P_LogMsg to procedure P_CheckPOR;
grant execute on procedure P_SyncPOR to procedure P_CheckPOR;
grant execute on procedure P_Register to procedure P_CheckPOR;
grant execute on procedure P_IpOrDBChanged to procedure P_CheckPOR;

grant execute on procedure P_ClearBackLog to procedure P_ClearLogs;
grant execute on procedure P_ClearMeltingPot to procedure P_ClearLogs;

grant all on P_TBacklog to procedure P_Sweep;
grant select on P_TParams to procedure P_Sweep;
grant all on P_TMeltingPot to procedure P_Sweep;
/*-----------------------------------------------------------------------------------------------*/


param_list(wg_avg_wage,in,[pConnection-bogem,pMonthQty-12,pAvgDays-29.7,pFeeGroupKey-147060452,pBadHourType_xid_IN-'147650804, 147650786, 147650802',pBadHourType_dbid_IN-'119619099',pBadFeeType_xid_IN-'151000730',pBadFeeType_dbid_IN-'2109681374']).
param_list(wg_avg_wage,in,[pEmplKey-148441437,pFirstMoveKey-148454058,pDateCalc-'2013-07-15',pMonthOffset-0]).
param_list(wg_avg_wage,run,[pEmplKey-148441437,pFirstMoveKey-148454058,pDateCalc-'2013-07-15',pMonthOffset-0,pDateCalcFrom-'2012-07-01',pDateCalcTo-'2013-07-01',pDateNormFrom-'2013-01-01',pDateNormTo-'2014-01-01',pConnection-bogem,pMonthQty-12,pAvgDays-29.7,pFeeGroupKey-147060452,pBadHourType_xid_IN-'147650804, 147650786, 147650802',pBadHourType_dbid_IN-'119619099',pBadFeeType_xid_IN-'151000730',pBadFeeType_dbid_IN-'2109681374']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_MovementLine/8,pSQL-'SELECT ml.USR$EMPLKEY, ml.DOCUMENTKEY, ml.USR$FIRSTMOVE AS FirstMoveKey, ml.USR$DATEBEGIN, ml.USR$SCHEDULEKEY, ml.USR$MOVEMENTTYPE, ml.USR$RATE, ml.USR$LISTNUMBER FROM USR$WG_MOVEMENTLINE ml WHERE ml.USR$EMPLKEY = 148441437 AND ml.USR$FIRSTMOVE = 148454058 ORDER BY ml.USR$EMPLKEY, ml.USR$FIRSTMOVE, ml.USR$DATEBEGIN ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblDayNorm/8,pSQL-'SELECT EmplKey, FirstMoveKey, TheDay, WYear, WMonth, WDay, WDuration, WorkDay FROM USR$WG_TBLCALDAY_P(148441437, 148454058, ''2012-07-01'', ''2013-07-01'') ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblYearNorm/5,pSQL-'SELECT EmplKey, FirstMoveKey, WYear, SUM(WDuration) AS WHoures, SUM(WorkDay) AS WDays FROM USR$WG_TBLCALDAY_P(148441437, 148454058, ''2013-01-01'', ''2014-01-01'') GROUP BY EmplKey, FirstMoveKey, WYear ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblCalLine/5,pSQL-'SELECT tc.USR$EMPLKEY, tc.USR$FIRSTMOVEKEY, tcl.USR$DATE, tcl.USR$DURATION, tcl.USR$HOURTYPE FROM USR$WG_TBLCAL tc JOIN USR$WG_TBLCALLINE tcl ON tcl.MASTERKEY = tc.DOCUMENTKEY WHERE tc.USR$EMPLKEY = 148441437 AND tc.USR$FIRSTMOVEKEY = 148454058 AND tcl.USR$DATE >= ''2012-07-01'' AND tcl.USR$DATE < ''2013-07-01'' ORDER BY tc.USR$EMPLKEY, tc.USR$FIRSTMOVEKEY, tcl.USR$DATE ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblCal_FlexLine/65,pSQL-'SELECT tcfl.USR$EMPLKEY, tcfl.USR$FIRSTMOVEKEY, t.USR$DATEBEGIN, tcfl.USR$S1, tcfl.USR$H1, tcfl.USR$S2, tcfl.USR$H2, tcfl.USR$S3, tcfl.USR$H3, tcfl.USR$S4, tcfl.USR$H4, tcfl.USR$S5, tcfl.USR$H5, tcfl.USR$S6, tcfl.USR$H6, tcfl.USR$S7, tcfl.USR$H7, tcfl.USR$S8, tcfl.USR$H8, tcfl.USR$S9, tcfl.USR$H9, tcfl.USR$S10, tcfl.USR$H10, tcfl.USR$S11, tcfl.USR$H11, tcfl.USR$S12, tcfl.USR$H12, tcfl.USR$S13, tcfl.USR$H13, tcfl.USR$S14, tcfl.USR$H14, tcfl.USR$S15, tcfl.USR$H15, tcfl.USR$S16, tcfl.USR$H16, tcfl.USR$S17, tcfl.USR$H17, tcfl.USR$S18, tcfl.USR$H18, tcfl.USR$S19, tcfl.USR$H19, tcfl.USR$S20, tcfl.USR$H20, tcfl.USR$S21, tcfl.USR$H21, tcfl.USR$S22, tcfl.USR$H22, tcfl.USR$S23, tcfl.USR$H23, tcfl.USR$S24, tcfl.USR$H24, tcfl.USR$S25, tcfl.USR$H25, tcfl.USR$S26, tcfl.USR$H26, tcfl.USR$S27, tcfl.USR$H27, tcfl.USR$S28, tcfl.USR$H28, tcfl.USR$S29, tcfl.USR$H29, tcfl.USR$S30, tcfl.USR$H30, tcfl.USR$S31, tcfl.USR$H31 FROM USR$WG_TBLCAL_FLEXLINE tcfl JOIN USR$WG_TBLCAL_FLEX tcf ON tcf.DOCUMENTKEY = tcfl.MASTERKEY JOIN USR$WG_TOTAL t ON t.DOCUMENTKEY = tcf.USR$TOTALDOCKEY WHERE tcfl.USR$EMPLKEY = 148441437 AND tcfl.USR$FIRSTMOVEKEY = 148454058 AND t.USR$DATEBEGIN >= ''2012-07-01'' AND t.USR$DATEBEGIN < ''2013-07-01'' ORDER BY tcfl.USR$EMPLKEY, tcfl.USR$FIRSTMOVEKEY, t.USR$DATEBEGIN ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_HourType/12,pSQL-'SELECT 148441437 AS EmplKey, 148454058 AS FirstMoveKey, ht.ID, ht.USR$CODE, ht.USR$DIGITCODE, ht.USR$DISCRIPTION ,
  ht.USR$ISWORKED, ht.USR$SHORTNAME, ht.USR$FORCALFLEX, ht.USR$FOROVERTIME, ht.USR$FORFLEX, ht.USR$ABSENTEEISM FROM USR$WG_HOURTYPE ht ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblCharge/5,pSQL-'SELECT tch.USR$EMPLKEY, tch.USR$FIRSTMOVEKEY, tch.USR$DATEBEGIN, tch.USR$DEBIT, tch.USR$FEETYPEKEY FROM USR$WG_TBLCHARGE tch WHERE tch.USR$EMPLKEY = 148441437 AND tch.USR$DEBIT > 0 AND tch.USR$DATEBEGIN >= ''2012-07-01'' AND tch.USR$DATEBEGIN < ''2013-07-01'' ORDER BY tch.USR$EMPLKEY, tch.USR$DATEBEGIN ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_FeeType/4,pSQL-'SELECT 148441437 AS EmplKey,  148454058 AS FirstMoveKey, ft.USR$WG_FEEGROUPKEY, ft.USR$WG_FEETYPEKEY FROM USR$CROSS179_256548741 ft WHERE
  ft.USR$WG_FEEGROUPKEY = 147060452 ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_BadHourType/3,pSQL-'SELECT 148441437 AS EmplKey, 148454058 AS FirstMoveKey, id FROM USR$WG_HOURTYPE WHERE id IN (SELECT id FROM gd_ruid WHERE xid IN (147650804, 147650786, 147650802) AND dbid IN (119619099) ) ']).
param_list(wg_avg_wage,query,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_BadFeeType/3,pSQL-'SELECT 148441437 AS EmplKey, 148454058 AS FirstMoveKey, id FROM USR$WG_FEETYPE WHERE id IN (SELECT id FROM gd_ruid WHERE xid IN (151000730) AND dbid IN (2109681374) ) ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_MovementLine/8,pSQL-'SELECT ml.USR$EMPLKEY, ml.DOCUMENTKEY, ml.USR$FIRSTMOVE AS FirstMoveKey, ml.USR$DATEBEGIN, ml.USR$SCHEDULEKEY, ml.USR$MOVEMENTTYPE, ml.USR$RATE, ml.USR$LISTNUMBER FROM USR$WG_MOVEMENTLINE ml WHERE ml.USR$EMPLKEY = 148441437 AND ml.USR$FIRSTMOVE = 148454058 ORDER BY ml.USR$EMPLKEY, ml.USR$FIRSTMOVE, ml.USR$DATEBEGIN ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblDayNorm/8,pSQL-'SELECT EmplKey, FirstMoveKey, TheDay, WYear, WMonth, WDay, WDuration, WorkDay FROM USR$WG_TBLCALDAY_P(148441437, 148454058, ''2012-07-01'', ''2013-07-01'') ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblYearNorm/5,pSQL-'SELECT EmplKey, FirstMoveKey, WYear, SUM(WDuration) AS WHoures, SUM(WorkDay) AS WDays FROM USR$WG_TBLCALDAY_P(148441437, 148454058, ''2013-01-01'', ''2014-01-01'') GROUP BY EmplKey, FirstMoveKey, WYear ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblCalLine/5,pSQL-'SELECT tc.USR$EMPLKEY, tc.USR$FIRSTMOVEKEY, tcl.USR$DATE, tcl.USR$DURATION, tcl.USR$HOURTYPE FROM USR$WG_TBLCAL tc JOIN USR$WG_TBLCALLINE tcl ON tcl.MASTERKEY = tc.DOCUMENTKEY WHERE tc.USR$EMPLKEY = 148441437 AND tc.USR$FIRSTMOVEKEY = 148454058 AND tcl.USR$DATE >= ''2012-07-01'' AND tcl.USR$DATE < ''2013-07-01'' ORDER BY tc.USR$EMPLKEY, tc.USR$FIRSTMOVEKEY, tcl.USR$DATE ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblCal_FlexLine/65,pSQL-'SELECT tcfl.USR$EMPLKEY, tcfl.USR$FIRSTMOVEKEY, t.USR$DATEBEGIN, tcfl.USR$S1, tcfl.USR$H1, tcfl.USR$S2, tcfl.USR$H2, tcfl.USR$S3, tcfl.USR$H3, tcfl.USR$S4, tcfl.USR$H4, tcfl.USR$S5, tcfl.USR$H5, tcfl.USR$S6, tcfl.USR$H6, tcfl.USR$S7, tcfl.USR$H7, tcfl.USR$S8, tcfl.USR$H8, tcfl.USR$S9, tcfl.USR$H9, tcfl.USR$S10, tcfl.USR$H10, tcfl.USR$S11, tcfl.USR$H11, tcfl.USR$S12, tcfl.USR$H12, tcfl.USR$S13, tcfl.USR$H13, tcfl.USR$S14, tcfl.USR$H14, tcfl.USR$S15, tcfl.USR$H15, tcfl.USR$S16, tcfl.USR$H16, tcfl.USR$S17, tcfl.USR$H17, tcfl.USR$S18, tcfl.USR$H18, tcfl.USR$S19, tcfl.USR$H19, tcfl.USR$S20, tcfl.USR$H20, tcfl.USR$S21, tcfl.USR$H21, tcfl.USR$S22, tcfl.USR$H22, tcfl.USR$S23, tcfl.USR$H23, tcfl.USR$S24, tcfl.USR$H24, tcfl.USR$S25, tcfl.USR$H25, tcfl.USR$S26, tcfl.USR$H26, tcfl.USR$S27, tcfl.USR$H27, tcfl.USR$S28, tcfl.USR$H28, tcfl.USR$S29, tcfl.USR$H29, tcfl.USR$S30, tcfl.USR$H30, tcfl.USR$S31, tcfl.USR$H31 FROM USR$WG_TBLCAL_FLEXLINE tcfl JOIN USR$WG_TBLCAL_FLEX tcf ON tcf.DOCUMENTKEY = tcfl.MASTERKEY JOIN USR$WG_TOTAL t ON t.DOCUMENTKEY = tcf.USR$TOTALDOCKEY WHERE tcfl.USR$EMPLKEY = 148441437 AND tcfl.USR$FIRSTMOVEKEY = 148454058 AND t.USR$DATEBEGIN >= ''2012-07-01'' AND t.USR$DATEBEGIN < ''2013-07-01'' ORDER BY tcfl.USR$EMPLKEY, tcfl.USR$FIRSTMOVEKEY, t.USR$DATEBEGIN ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_HourType/12,pSQL-'SELECT 148441437 AS EmplKey, 148454058 AS FirstMoveKey, ht.ID, ht.USR$CODE, ht.USR$DIGITCODE, ht.USR$DISCRIPTION ,
  ht.USR$ISWORKED, ht.USR$SHORTNAME, ht.USR$FORCALFLEX, ht.USR$FOROVERTIME, ht.USR$FORFLEX, ht.USR$ABSENTEEISM FROM USR$WG_HOURTYPE ht ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_TblCharge/5,pSQL-'SELECT tch.USR$EMPLKEY, tch.USR$FIRSTMOVEKEY, tch.USR$DATEBEGIN, tch.USR$DEBIT, tch.USR$FEETYPEKEY FROM USR$WG_TBLCHARGE tch WHERE tch.USR$EMPLKEY = 148441437 AND tch.USR$DEBIT > 0 AND tch.USR$DATEBEGIN >= ''2012-07-01'' AND tch.USR$DATEBEGIN < ''2013-07-01'' ORDER BY tch.USR$EMPLKEY, tch.USR$DATEBEGIN ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_FeeType/4,pSQL-'SELECT 148441437 AS EmplKey,  148454058 AS FirstMoveKey, ft.USR$WG_FEEGROUPKEY, ft.USR$WG_FEETYPEKEY FROM USR$CROSS179_256548741 ft WHERE
  ft.USR$WG_FEEGROUPKEY = 147060452 ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_BadHourType/3,pSQL-'SELECT 148441437 AS EmplKey, 148454058 AS FirstMoveKey, id FROM USR$WG_HOURTYPE WHERE id IN (SELECT id FROM gd_ruid WHERE xid IN (147650804, 147650786, 147650802) AND dbid IN (119619099) ) ']).
param_list(wg_avg_wage,data,[pEmplKey-148441437,pFirstMoveKey-148454058,pConnection-bogem,pQuery-usr_wg_BadFeeType/3,pSQL-'SELECT 148441437 AS EmplKey, 148454058 AS FirstMoveKey, id FROM USR$WG_FEETYPE WHERE id IN (SELECT id FROM gd_ruid WHERE xid IN (151000730) AND dbid IN (2109681374) ) ']).

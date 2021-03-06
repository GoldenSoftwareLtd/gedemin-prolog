'#include pl_GetScriptIDByName
Option Explicit

Function wg_CalcAvgAddPay_pl(ByRef gdcObject, ByRef gdcDetailObject, ByRef gdcSalary, _
                             ByVal MonthBefore, ByVal MonthOffset, ByRef PL)
'
  Dim T, T1, T2
  '
  Dim Creator
  '
  'Dim PL
  Dim Ret, Pred, Tv, Append
  Dim PredFile, Scope
  'avg_wage
  Dim P_main, Tv_main, Q_main
  'avg_wage_avg_in
  Dim P_in, Tv_in, Q_in
  Dim EmplKey, FirstMoveKey, DateCalc, CalcByHoure
  'avg_wage_run, avg_wage_sql
  Dim P_run, Tv_run, Q_run, P_sql, Tv_sql, Q_sql, P_kb
  Dim DateCalcFrom, DateCalcTo
  Dim PredicateName, Arity, SQL
  'avg_wage_out, avg_wage_avg_det
  Dim P_out, Tv_out, Q_out, P_det, Tv_det, Q_det
  Dim AvgWage, AvgWageRule
  Dim Period, Wage
  Dim TabDays, TabHoures, NormDays, NormHoures
  'avg_wage_clean
  Dim P_cl, Tv_cl, Q_cl

  T1 = Timer
  wg_CalcAvgAddPay_pl = ""

  'init
  Set Creator = New TCreator
  'Set PL = Creator.GetObject(nil, "TgsPLClient", "")
  'Ret = PL.Initialise("")
  'If Not Ret Then
  '  Exit Function
  'End If
  'debug
  'PL.Debug = True
  'load
  'Ret = PL.LoadScript(pl_GetScriptIDByName("twg_avg_wage"))
  'If Not Ret Then
  '  Exit Function
  'End If
  Scope = "wg_avg_wage_avg"

  'params
  CalcByHoure = gdcObject.FieldByName("USR$CALCBYHOUR").AsInteger
  EmplKey = gdcDetailObject.FieldByName("usr$emplkey").AsInteger
  FirstMoveKey = gdcDetailObject.FieldByName("usr$firstmovekey").AsInteger
  '
  Dim IBSQL
  '
  Set IBSQL = Creator.GetObject(nil, "TIBSQL", "")
  IBSQL.Transaction = gdcBaseManager.ReadTransaction
  IBSQL.SQL.Text = _
      "SELECT " & _
      "  t.USR$DATEBEGIN " & _
      "FROM " & _
      "  USR$WG_TOTAL t " & _
      "WHERE " & _
      "  t.DOCUMENTKEY = :TDK "
  IBSQL.ParamByName("TDK").AsInteger = gdcObject.FieldByName("USR$TOTALDOCKEY").AsInteger
  IBSQL.ExecQuery
  '
  DateCalc = IBSQL.FieldByName("USR$DATEBEGIN").AsDateTime
  '
  IBSQL.Close
  '

  'clean
  gdcSalary.First
  While Not gdcSalary.EOF
    gdcSalary.Delete
  Wend
  '
  gdcSalary.OwnerForm.Repaint

  'avg_wage_avg_in(EmplKey, FirstMoveKey, DateCalc, CalcByHoure, MonthBefore, MonthOffset)
  P_in = "avg_wage_avg_in"
  Set Tv_in = Creator.GetObject(6, "TgsPLTermv", "")
  Set Q_in = Creator.GetObject(nil, "TgsPLQuery", "")
  Tv_in.PutInteger 0, EmplKey
  Tv_in.PutInteger 1, FirstMoveKey
  Tv_in.PutDate 2, DateCalc
  Tv_in.PutInteger 3, CalcByHoure
  Tv_in.PutInteger 4, MonthBefore
  Tv_in.PutInteger 5, MonthOffset
  '
  Q_in.PredicateName = P_in
  Q_in.Termv = Tv_in
  '
  Q_in.OpenQuery
  If Q_in.EOF Then
    Exit Function
  End If
  Q_in.Close

  'save param_list
  If PL.Debug Then
    Pred = "param_list"
    PredFile = "param_list_in"
    Set Tv = Creator.GetObject(3, "TgsPLTermv", "")
    PL.SavePredicatesToFile Pred, Tv, PredFile
  End If

  'avg_wage(Scope) - prepare data
  P_main = "avg_wage"
  Set Tv_main = Creator.GetObject(1, "TgsPLTermv", "")
  Set Q_main = Creator.GetObject(nil, "TgsPLQuery", "")
  Q_main.PredicateName = P_main
  Q_main.Termv = Tv_main
  '
  Tv_main.PutAtom 0, Scope
  '
  Q_main.OpenQuery
  If Q_main.EOF Then
    Exit Function
  End If
  Q_main.Close

  'save param_list
  If PL.Debug Then
    Pred = "param_list"
    PredFile = "param_list_prep"
    Set Tv = Creator.GetObject(3, "TgsPLTermv", "")
    PL.SavePredicatesToFile Pred, Tv, PredFile
  End If

  'avg_wage_run(Scope, EmplKey, FirstMoveKey, DateCalcFrom, DateCalcTo)
  P_run = "avg_wage_run"
  Set Tv_run = Creator.GetObject(5, "TgsPLTermv", "")
  Set Q_run = Creator.GetObject(nil, "TgsPLQuery", "")
  Q_run.PredicateName = P_run
  Q_run.Termv = Tv_run
  'avg_wage_sql(Scope, EmplKey, FirstMoveKey, PredicateName, Arity, SQL)
  P_sql = "avg_wage_sql"
  P_kb = "avg_wage_kb"
  Set Tv_sql = Creator.GetObject(6, "TgsPLTermv", "")
  Set Q_sql = Creator.GetObject(nil, "TgsPLQuery", "")
  Q_sql.PredicateName = P_sql
  Q_sql.Termv = Tv_sql
  '
  Tv_run.PutAtom 0, Scope
  '
  Q_run.OpenQuery
  If Q_run.EOF Then
    Exit Function
  End If
  '
  Append = False
  '
  Do Until Q_run.EOF
    EmplKey = Tv_run.ReadInteger(1)
    FirstMoveKey = Tv_run.ReadInteger(2)
    DateCalcFrom = Tv_run.ReadDate(3)
    DateCalcTo = Tv_run.ReadDate(4)
    '
    Tv_sql.Reset
    Tv_sql.PutAtom 0, Scope
    Tv_sql.PutInteger 1, EmplKey
    Tv_sql.PutInteger 2, FirstMoveKey
    Q_sql.OpenQuery
    '
    Do Until Q_sql.EOF
      PredicateName = Tv_sql.ReadAtom(3)
      Arity = Tv_sql.ReadInteger(4)
      SQL = Tv_sql.ReadString(5)
      '
      Ret =  PL.MakePredicatesOfSQLSelect _
                (SQL, _
                gdcBaseManager.ReadTransaction, _
                PredicateName, PredicateName, Append)
      If Ret >= 0 Then
         Ret = PL.Call(P_kb, Tv_sql)
      End If
      '
      Q_sql.NextSolution
    Loop
    Q_sql.Close
    '
    Append = True
    '
    Q_run.NextSolution
  Loop
  Q_run.Close

  'save param_list
  If PL.Debug Then
    Pred = "param_list"
    PredFile = "param_list_sql"
    Set Tv = Creator.GetObject(3, "TgsPLTermv", "")
    PL.SavePredicatesToFile Pred, Tv, PredFile
  End If

  'avg_wage(Scope) - calc result
  Q_main.OpenQuery
  If Q_main.EOF Then
    Exit Function
  End If
  Q_main.Close

  'avg_wage_out(Scope, EmplKey, FirstMoveKey, AvgWage, AvgWageVariant)
  P_out = "avg_wage_out"
  Set Tv_out = Creator.GetObject(5, "TgsPLTermv", "")
  Set Q_out = Creator.GetObject(nil, "TgsPLQuery", "")
  Q_out.PredicateName = P_out
  Q_out.Termv = Tv_out
  'avg_wage_avg_det(EmplKey, FirstMoveKey,
  '                  Period, Wage,
  '                  TabDays, NormDays, TabHoures, NormHoures) :-
  P_det = "avg_wage_avg_det"
  Set Tv_det = Creator.GetObject(8, "TgsPLTermv", "")
  Set Q_det = Creator.GetObject(nil, "TgsPLQuery", "")
  Q_det.PredicateName = P_det
  Q_det.Termv = Tv_det
  '
  Tv_out.PutAtom 0, Scope
  '
  Q_out.OpenQuery
  If Q_out.EOF Then
    'Exit Function
  End If
  '
  Do Until Q_out.EOF
    EmplKey = Tv_out.ReadInteger(1)
    FirstMoveKey = Tv_out.ReadInteger(2)
    AvgWage = Tv_out.ReadFloat(3)
    AvgWageRule = Tv_out.ReadAtom(4)
    '
    wg_CalcAvgAddPay_pl = AvgWageRule
    Select Case AvgWageRule
      Case "avg_houre", "avg_day"
        '
      Case Else
        Exit Do
    End Select
    '
    Tv_det.Reset
    Tv_det.PutInteger 0, EmplKey
    Tv_det.PutInteger 1, FirstMoveKey
    Q_det.OpenQuery
    '
    Do Until Q_det.EOF
      Period = Tv_det.ReadDate(2)
      Wage = Tv_det.ReadFloat(3)
      TabDays = Tv_det.ReadFloat(4)
      NormDays = Tv_det.ReadFloat(5)
      TabHoures = Tv_det.ReadFloat(6)
      NormHoures = Tv_det.ReadFloat(7)
      '
      gdcSalary.Append
      gdcSalary.FieldByName("USR$ISCHECK").AsVariant = Abs( Wage > 0 )
      gdcSalary.FieldByName("USR$DATE").AsVariant = Period
      If Wage > 0 Then
        gdcSalary.FieldByName("USR$SALARY").AsVariant = Wage
        gdcSalary.FieldByName("USR$DOW").AsVariant = TabDays
        gdcSalary.FieldByName("USR$SCHEDULERDOW").AsVariant = NormDays
        gdcSalary.FieldByName("USR$HOW").AsVariant = TabHoures
        gdcSalary.FieldByName("USR$SCHEDULERHOW").AsVariant = NormHoures
      End If
      gdcSalary.Post
      '
      Q_det.NextSolution
    Loop
    Q_det.Close
    '
    Q_out.NextSolution
  Loop
  Q_out.Close
  '

  'save param_list
  If PL.Debug Then
    Pred = "param_list"
    PredFile = "param_list_out"
    Set Tv = Creator.GetObject(3, "TgsPLTermv", "")
    PL.SavePredicatesToFile Pred, Tv, PredFile
  End If

  'avg_wage_clean(Scope, EmplKey, FirstMoveKey)
  P_cl = "avg_wage_clean"
  Set Tv_cl = Creator.GetObject(3, "TgsPLTermv", "")
  Set Q_cl = Creator.GetObject(nil, "TgsPLQuery", "")
  Tv_cl.PutAtom 0, Scope
  Tv_cl.PutInteger 1, EmplKey
  Tv_cl.PutInteger 2, FirstMoveKey
  '
  Q_cl.PredicateName = P_cl
  Q_cl.Termv = Tv_cl
  '
  Q_cl.OpenQuery
  If Q_cl.EOF Then
    Exit Function
  End If
  Q_cl.Close

  If AvgWage > 0 Then
    gdcSalary.First

    gdcDetailObject.Edit
    gdcDetailObject.FieldByName("USR$AVGSUM").AsCurrency = AvgWage
    gdcDetailObject.Post
  End If
  
  T2 = Timer
  T = T2 - T1
'
End function

Option Explicit
'#include pl_GetScriptIDByName
Sub Gedemin_Prolog_blog_2013_08_29()
'subject close to the
'http://gedemin.blogspot.com/2013/08/embedded-swi-prolog.html
  Dim Creator, PL, Termv, Query, Ret
  Dim SQL_contact, SQL_place
  'Dim Pred
  Dim City, CDS, I
  
  SQL_contact = _
      "SELECT ID, PlaceKey, Name FROM gd_contact"
  SQL_place = _
      "SELECT ID, Name FROM gd_place"

  Set Creator = New TCreator
  '
  Set PL = Creator.GetObject(nil, "TgsPLClient", "")
  Ret = PL.Initialise("")
  If Not Ret Then Exit Sub
  
  Ret = PL.MakePredicatesOfSQLSelect( _
          SQL_contact, _
          gdcBaseManager.ReadTransaction, _
          "gd_contact", "contact")

  Ret = PL.MakePredicatesOfSQLSelect( _
          SQL_place, _
          gdcBaseManager.ReadTransaction, _
          "gd_place", "place")

  Set Termv = Creator.GetObject(2, "TgsPLTermv", "")
  Ret = PL.LoadScript(pl_GetScriptIDByName("blog_2013_08_29"))
  If Not Ret Then Exit Sub

  City = InputBox("������� �����", "�����", "�����")
  Termv.Reset
  Termv.PutString 0, City
  Ret = PL.Call("bycity", Termv)
  If Not Ret Then Exit Sub

  Ret = Termv.ReadString(1)
  MsgBox Ret, , "Call: ������ �������"
  
  Set CDS = Creator.GetObject(nil, "TClientDataset", "")
  CDS.FieldDefs.Add "City", ftString, 60, True
  CDS.FieldDefs.Add "Name", ftString, 60, True
  CDS.CreateDataSet
  CDS.Open

  Termv.Reset
  Termv.PutString 0, City
  PL.ExtractData CDS, "bycity", Termv
  If CDS.RecordCount = 0 Then Exit Sub
  
  Ret = "" : I = 0
  CDS.First
  Do Until CDS.Eof Or I = 10
     Ret = Ret + CDS.FieldByName("Name").AsString + VBCrLf
     I = I + 1
     CDS.Next
  Loop
  MsgBox Ret, , "MakePredicatesOfSQLSelect: ������ 10 ���������"

  I = 0
  CDS.First
  Do Until CDS.Eof Or I = 5
     CDS.Delete
     I = I + 1
  Loop

  Ret = PL.MakePredicatesOfDataSet( _
          CDS, _
          "City,Name", _
          "gd_bycity", "bycity")

  Ret = PL.Call2("dynamic(gd_bycity/2)")
  Termv.Reset
  Ret = PL.Call("gd_bycity", Termv)
  
  If Ret Then
    Ret = Termv.ReadString(1) + " (" + Termv.ReadString(0) + ")"
  Else
    Ret = "���� ������� ������ 6 ���������"
  End If
  MsgBox Ret, , "MakePredicatesOfDataSet: ������� 6"

  Ret = PL.MakePredicatesOfObject( _
          "TgdcCurr", "", "ByID", Array(200010, 200020), nil, _
          "ID,Name", _
          gdcBaseManager.ReadTransaction, _
          "gd_curr", "curr")

  Termv.Reset
  Termv.PutInteger 0, 200020
  Ret = PL.Call("gd_curr", Termv)
  If Not Ret Then Exit Sub
  
  Ret = CStr(Termv.ReadInteger(0)) + ": " + Termv.ReadString(1)
  MsgBox Ret, , "MakePredicatesOfObject: ������"
  
  Set Query = Creator.GetObject(nil, "TgsPLQuery", "")
  Query.PredicateName = "current_foreign_library"
  Termv.Reset
  Query.Termv = Termv
  Query.OpenQuery
  
  Ret = ""
  Do Until Query.EOF
     Ret = Ret + Query.Termv.ToString(0) + VBCrLf
     Query.NextSolution
  Loop
  MsgBox Ret, , "Query: current_foreign_library"
End Sub

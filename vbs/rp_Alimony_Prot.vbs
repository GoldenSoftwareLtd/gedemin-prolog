Option Explicit
Function rp_Alimony_Prot(OwnerForm, TotalDocKey)
  Dim qProt
  Dim gdcObject, EmplKey, FeeTypeKey

  Set gdcObject = OwnerForm.gdcObject
  EmplKey = gdcObject.FieldByName("USR$EMPLKEY").AsInteger
  FeeTypeKey = gdcBaseManager.GetIDByRUIDString(wg_FeeType_Alimony_RUID)

  BaseQueryList.Clear
  Set qProt = BaseQueryList.Query(BaseQueryList.Add("Prot", 0))
  qProt.SQL = _
    " SELECT * FROM USR$WG_TBLCHARGE_PROT" & _
    " WHERE" & _
    "       USR$EMPLKEY = " & EmplKey & _
    "   AND USR$TOTALDOCKEY = " & TotalDocKey(0) & _
    "   AND USR$FEETYPEKEY = " & FeeTypeKey
  qProt.Open

  Set rp_Alimony_Prot = BaseQueryList
End Function

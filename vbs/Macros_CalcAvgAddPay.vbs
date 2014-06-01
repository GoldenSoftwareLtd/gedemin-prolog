'#include wg_CalcAvgAddPay_pl
Option Explicit

Sub Macros_CalcAvgAddPay(OwnerForm)
'
  Dim gdcObject, gdcDetailObject, gdcSalary, Ret

  OwnerForm.GetComponent("actApply").Execute

  Set gdcObject = OwnerForm.gdcObject
  Set gdcDetailObject = OwnerForm.gdcDetailObject
  Set gdcSalary = OwnerForm.GetComponent("usrg_gdcAvgSalaryStr")
  
  Dim MonthBefore
  MonthBefore = 0
  Do
    Ret = wg_CalcAvgAddPay_pl(gdcObject, gdcDetailObject, gdcSalary, MonthBefore)
    Select Case Ret
      Case "need_more"
        MonthBefore = MonthBefore + 1
      Case Else
        Exit Do
    End Select
  Loop
'
End Sub

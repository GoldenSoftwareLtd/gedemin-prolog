' ��� ������ ��������� ��� ��������, ������ �� ��� ���
' ���������� �������������� ������� �������� ����� �����
' ���� ��� ����� ������� �� ����

Option Explicit
'#include wg_AvgSalaryDetailGenerate_pl
'#include wg_AvgSalaryStrGenerate_pl

Sub Macros_Vacation_Recalc(OwnerForm)
'
  Dim gdcObject, gdcDetail, gdcAvgStr, Creator, inID, Ret
  Set gdcObject = OwnerForm.gdcObject
  Set gdcDetail = OwnerForm.gdcDetailObject

  Dim CalcType, Silence
  CalcType = 0
  Silence = 1
  
  Dim InflType, InflFCType
  Dim MonthOffset, CoefOption
  '
  InflType = wg_WageSettings.Inflation.InflType
  InflFCType = wg_WageSettings.Inflation.InflFCType
  'CoefOption: fc_fcratesum ; ml_rate ; ml_msalary
  Select Case InflType
    'usrg_rbSalaryInf - �� ������
    Case 0
      CoefOption = "ml_msalary"
    'usrg_rbRateInf - �� ������ 1-�� �������
    Case 1
      Select Case InflFCType
        'usrg_rbFCRate - �����������
        Case 0
          CoefOption = "fc_fcratesum"
        'usrg_rbMovementRate - ��������� ��������
        Case 2
          CoefOption = "ml_rate"
      End Select
  End Select
  '

  '�������� wg_WageSettings
  'CoefOption = "ml_rate" '������ ��� ���, ����� ��� ������ ����������������

  MonthOffset = 0

  gdcObject.First
  inID = ""
  '
  While Not gdcObject.eof
    If inID = "" Then
      inID = gdcObject.ID
    Else
      inID = inID & ", " & gdcObject.ID
    End If
    '
    gdcObject.Next
  Wend
  '
  inID = "(" & inID & ")"
  gdcObject.ExtraConditions.Add(" z.id in " & inID )

  Set Creator = New TCreator
  Set gdcAvgStr = Creator.GetObject(OwnerForm, "TgdcAttrUserDefined", "")
  gdcAvgStr.SubType = "USR$WG_AVGSALARYSTR"
  gdcAvgStr.Transaction = gdcObject.Transaction
  gdcAvgStr.ReadTransaction = gdcObject.ReadTransaction
  gdcAvgStr.SubSet = "ByParent"
  gdcAvgStr.MasterSource = OwnerForm.GetComponent("dsMain")
  gdcAvgStr.MasterField = "ID"
  gdcAvgStr.DetailField = "PARENT"
  gdcAvgStr.Open

  gdcObject.First
  '
  While Not gdcObject.EOF
    gdcObject.Edit
    
    Ret = wg_AvgSalaryStrGenerate_pl(gdcObject, gdcAvgStr, _
                                     CalcType, Silence, _
                                     MonthOffset, CoefOption)
    Ret = wg_AvgSalaryDetailGenerate_pl(gdcObject, gdcDetail, Silence)
    '
    gdcObject.Next
  Wend

  gdcObject.ExtraConditions.Clear
'
End Sub

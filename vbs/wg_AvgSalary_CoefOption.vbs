Option Explicit
'#include wg_WageSettings

Sub wg_AvgSalary_CoefOption(ByRef Sender)
'
  Dim InflType, InflFCType
  Dim rbFCRate, rbRateInf, rbMovementRate, rbSalaryInf
  
  InflType = wg_WageSettings.Inflation.InflType
  InflFCType = wg_WageSettings.Inflation.InflFCType
  '
  '�� ������
  Set rbSalaryInf = Sender.GetComponent("usrg_rbSalaryInf")
  rbSalaryInf.Checked = False
  '�� ������ 1-�� �������
  Set rbRateInf = Sender.FindComponent("usrg_rbRateInf")
  rbRateInf.Checked = False
  '  �����������
  Set rbFCRate = Sender.FindComponent("usrg_rbFCRate")
  rbFCRate.Checked = False
  '  ��������� ��������
  Set rbMovementRate = Sender.FindComponent("usrg_rbMovementRate")
  rbMovementRate.Checked = False
  '
  Select Case InflType
    'usrg_rbSalaryInf - �� ������
    Case 0
      rbSalaryInf.Checked = True
    'usrg_rbRateInf - �� ������ 1-�� �������
    Case 1
      rbRateInf.Checked = True
      '
      Select Case InflFCType
        'usrg_rbFCRate - �����������
        Case 0
          rbFCRate.Checked = True
        'usrg_rbMovementRate - ��������� ��������
        Case 2
          rbMovementRate.Checked = True
      End Select
      '
  End Select
'
End Sub

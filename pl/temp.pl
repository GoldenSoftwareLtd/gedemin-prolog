% Author:
% Date: 31.07.2013

%%
    % ��������� �� ����������� �����
    usr_wg_TotalLine(EmplKey, Y, M, Wage),
    % ��������� �� ��������� �������
    findall( Wage1,
        (
        % �� ��������� �����
        wg_month_incl(EmplKey, Y1, M1, Variant1),
        % �� �������� ������� ������
        wg_full_month_rules(Rules),
        member(Variant1, Rules),
        % ����� ���������
        usr_wg_TotalLine(EmplKey, Y1, M1, Wage1)
        ),
        % � ������ ����������
             Wages1 ),
    % ������������ ��������� �� ��������� �������
    max_member(MaxWage1, Wages1),
    % ��������� �� ����������� ��������� ������������
    Wage >= MaxWage1,

%%
    % ��������� �� ����������� ��������� ������ �� ��������� �������
    over_list(Wage, Wages1),
%
:- include(date).
:- include(lib).

:- multifile
    twg_AvgWage/4,
    usr_wg_MovementLine/7,
    usr_wg_TblCalDay/5,
    usr_wg_TblCalMonth/5,
    usr_wg_TblCalLine/6,
    usr_wg_TotalLine/4.

:- include(facts).
:- include(facts1).
:- include(facts2).

:- dynamic
    wg_avg_wage/3,
    wg_month_incl/4.

% �������������� ���������� ����������� ����
wg_avg_days(29.7).

% �������� ������ �������
wg_valid_rules([by_calc_month, by_avg_houre, by_day_houres, by_month_houres, by_month_wage_all, by_month_wage_one]).

% �������� ������ ������ �������
wg_full_month_rules([by_day_houres, by_month_houres]).

% ������� �������������
is_valid_rule(Rule) :-
    wg_valid_rules(ValidRules),
    member(Rule, ValidRules),
    !.

% ������������� ���������
avg_wage :-
    % ��������� �������
    twg_AvgWage(_, EmplKey, _, _),
    % �������� ������ �� �������������� ��������� �� ����������
    retractall( wg_avg_wage(EmplKey, _, _) ),
    % ������������� ��������� �� ����������
    avg_wage(EmplKey, AvgWage, Variant),
    % ���������� ����� �� �������������� ��������� �� ����������
    assertz( wg_avg_wage(EmplKey, AvgWage, Variant) ),
    % ����� ����� �� �������������� ��������� �� ����������
    write( wg_avg_wage(EmplKey, AvgWage, Variant) ), nl,
    % ����� ������������
    fail.

avg_wage.

% ������������� ��������� �� ���������� (�� ��������� �������)
avg_wage(EmplKey, AvgWage, Rule) :-
    Rule = by_calc_month,
    % ������� �������������
    is_valid_rule(Rule),
    % �������� ������ �� ��������� �������
    retractall( wg_month_incl(EmplKey, _, _, _) ),
    % ������� ��� ��������
    findall( Year-Month,
        % ����� ���-����� �� �������
        usr_wg_TblCalMonth(EmplKey, Year, Month, _, _),
        % � ������ ��������
             Periods ),
    % �������� �� ������
    check_month_tab(EmplKey, Periods),
    % ���� ���� �� ���� ��������� �����
    wg_month_incl(EmplKey, _, _, _),
    % �������� �� ���������
    check_month_wage(EmplKey, Periods),
    % ��������� �� ��������� �������
    findall( Wage,
        (
        % �� ��������� �����
        wg_month_incl(EmplKey, Y, M, _),
        % ����� ���������
        usr_wg_TotalLine(EmplKey, Y, M, Wage)
        ),
        % � ������ ����������
             Wages ),
    % ����� ��������� �� ��������� ������
    sum_list(Wages, Amount),
    % ���������� ��������� �������
    length(Wages, Num),
    % �������������� ���������� ����������� ����
    wg_avg_days(AvgDays),
    % ������������� ���������
    catch( AvgWage is Amount / Num / AvgDays, _, fail),
    !.

% ������������� ��������� �� ���������� (�� ��������������)
avg_wage(EmplKey, AvgWage, Rule) :-
    Rule = by_avg_houre,
    % ������� �������������
    is_valid_rule(Rule),
    % ��������� �� �������
    findall( Wage,
        % ����� ��������� �� �����
        usr_wg_TotalLine(EmplKey, _, _, Wage),
        % � ������ ����������
             Wages ),
    % ����� ��������� �� ������
    sum_list(Wages, Amount),
    % ���� �� ���� �� ������
    findall( Duration,
        % ����� ���� �� ������
        usr_wg_TblCalLine(EmplKey, _, Duration, _, _, _),
        % � ������ �����
             Durations ),
    % ����� ����� �� ������
    sum_list(Durations, TotalWork),
    % ������������� ���������
    catch( AvgHoureWage is Amount / TotalWork, _, fail ),
    % ��������� ����� �� �������
    findall( MonthNorm,
        % ����� ���� �� �����
        usr_wg_TblCalMonth(EmplKey, _, _, MonthNorm, _),
        % � ������ �����
             MonthNorms ),
    % ����� ����� �� �������
    sum_list(MonthNorms, TotalNorm),
    % ���������� ����������� �������
    length(MonthNorms, NumNorm),
    % �������������� ���������� ��������� ������� �����
    catch( AvgMonthNorm is TotalNorm / NumNorm, _, fail ),
    % �������������� ���������� ����������� ����
    wg_avg_days(AvgDays),
    % ������������� ���������
    catch( AvgWage is  AvgHoureWage * AvgMonthNorm / AvgDays, _, fail),
    !.
    
% �������� ������ �� ������
check_month_tab(_, []):-
    % ������ ������� ��� �������� ���
    true.

check_month_tab(EmplKey, [ Y-M | Periods ]) :-
    % ���� ����������� ���� �� ������
    rule_month_tab(EmplKey, Y-M, Variant),
    % �� �������� ���� ��������� ������ � ������
    assertz( wg_month_incl(EmplKey, Y, M, Variant) ),
    !,
    % ��������� ��������� �����
    check_month_tab(EmplKey, Periods).

check_month_tab(EmplKey, [ _ | Periods ]) :-
    !,
    % ��������� ��������� �����
    check_month_tab(EmplKey, Periods).

% ������� ��������� ������ � ������
rule_month_tab(EmplKey, YM, Rule) :-
    Rule = by_day_houres,
    % ������� �������������
    is_valid_rule(Rule),
    % ���� �� ���� �� ������ ��������� ������
    month_by_day_houres(EmplKey, YM).

rule_month_tab(EmplKey, YM, Rule) :-
    Rule = by_month_houres,
    % ������� �������������
    is_valid_rule(Rule),
    % ����� ����� �� ����� �� ������ ��������� ������
    month_by_month_houres(EmplKey, YM).

% ���� �� ���� �� ������ ��������� ������
month_by_day_houres(EmplKey, Y-M) :-
    % ���� ��� ������-���� �������� ��� �� �������
    usr_wg_TblCalDay(EmplKey, Date, Duration, 1, _),
    % ���� ��� �������� ��������� � ����������� �������
    atom_date(Date, date(Y, M, _)),
    % ���� ���� �� ���� �������������� �� ���� � �����
    \+ usr_wg_TblCalLine(EmplKey, Date, Duration, _, _, _),
    % �� ����� ����������� �� �������
    !,
    fail.

month_by_day_houres(_, _) :-
    % �����, ����� ���������� � ������
    true.

% ����� ����� �� ����� �� ������ ��������� ������
month_by_month_houres(EmplKey, Y-M) :-
    % ���� �� ������ �� �������
    usr_wg_TblCalMonth(EmplKey, Y, M, MonthNorm, _),
    % ���� �� ������ �� ������
    month_houres(EmplKey, Y, M, MonthTab),
    % ������ ��������� ������
    MonthTab >= MonthNorm.

% ����� ����� �� ����� �� ������
month_houres(EmplKey, Y, M, MonthTab) :-
    % ���� �� ���� � ������
    findall( Duration,
        (
        % ����� ���� �� ������
        usr_wg_TblCalLine(EmplKey, Date, Duration, _, _, _),
        % ��� ���� ������������� ������������ ������
        atom_date(Date, date(Y, M, _))
        ),
        % � ������ �����
             Durations),
    % ����� ����� �� ����� �� ������
    sum_list(Durations, MonthTab),
    !.

% �������� ������ �� ���������
check_month_wage(_, []):-
    % ������ ������� ��� �������� ���
    true.
    
check_month_wage(EmplKey, [ Y-M | Periods ]) :-
    % ���� ����� ��� �� ������� � ������
    \+ wg_month_incl(EmplKey, Y, M, _),
    % � ����������� ���� �� ������
    rule_month_wage(EmplKey, Y-M, Variant),
    % �� �������� ���� ��������� ������ � ������
    assertz( wg_month_incl(EmplKey, Y, M, Variant) ),
    !,
    % ��������� ��������� �����
    check_month_wage(EmplKey, Periods).

check_month_wage(EmplKey, [ _ | Periods ]) :-
    !,
    % ��������� ��������� �����
    check_month_wage(EmplKey, Periods).

% ��������� �� ����� ���� ��� �� ������ ������� �� ������ �������
rule_month_wage(EmplKey, YM, Rule) :-
    Rule = by_month_wage_all,
    % ������� �������������
    is_valid_rule(Rule),
    % ��������� �� ����������� ����� ��������� ������ �� ��������� �������
    over_month_incl(EmplKey, YM),
    !.

% ��������� �� ����� ���� ��� �� ������ ������ �� ������ �������
rule_month_wage(EmplKey, Y-M, Rule) :-
    Rule = by_month_wage_one,
    % ������� �������������
    is_valid_rule(Rule),
    % ��������� �� ����������� �����
    usr_wg_TotalLine(EmplKey, Y, M, Wage),
    % ���� ���� �� ���� ��������� �����
    wg_month_incl(EmplKey, Y1, M1, Variant1),
    % �� �������� ������� ������
    wg_full_month_rules(Rules),
    member(Variant1, Rules),
    % ��������� �� �������
    usr_wg_TotalLine(EmplKey, Y1, M1, Wage1),
    % ����������� ���������
    Wage >= Wage1,
    % �� ����� ���������� � ������
    !.

% ��������� �� ����������� ����� ��������� ������ �� ��������� �������
over_month_incl(EmplKey, Y-M) :-
    % ��������� �� ����������� �����
    usr_wg_TotalLine(EmplKey, Y, M, Wage),
    % ���� ���� ���� �� ���� ��������� �����
    wg_month_incl(EmplKey, Y1, M1, Variant1),
    % �� �������� ������� ������
    wg_full_month_rules(Rules),
    member(Variant1, Rules),
    % ��������� � �������
    usr_wg_TotalLine(EmplKey, Y1, M1, Wage1),
    % �� ����������� ���������
    \+ Wage >= Wage1,
    % �� ����� ����������� �� �������
    !,
    fail.

over_month_incl(_, _) :-
    % �����, ����� ���������� � ������
    true.

%

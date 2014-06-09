﻿%% twg_avg_wage
% Зарплата и Отдел кадров -> Зарплата -> 03. Начисление зарплаты
%   05. Начисление отпусков
%   06. Начисление больничных
%   12. Начисление по-среднему
%

:- retractall(debug_mode).

% ! при использовании в ТП Гедымин
% ! для begin & end debug mode section
% ! убрать символ процента из первой позиции
%/* %%% begin debug mode section

%% saved state
:- ['../gd_pl_state/load_atom', '../gd_pl_state/date', '../gd_pl_state/dataset'].
%%

%% include
%#INCLUDE lib
:- ['../common/lib'].
%#INCLUDE params
:- ['../common/params'].
%#INCLUDE twg_avg_wage_sql
:- [twg_avg_wage_sql].
%#INCLUDE twg_avg_wage_in_params
%:- [twg_avg_wage_in_params].
%%

%% facts
:-  init_data,
    working_directory(_, 'kb'),
    [
    % section twg_avg_wage
    %  05. Начисление отпусков
    usr_wg_DbfSums, % 05, 06, 12
    usr_wg_MovementLine, % 05, 06, 12
    usr_wg_FCRate,
    usr_wg_TblCalDay, % 05, 06, 12
    %usr_wg_TblDayNorm, % 05, 06, 12
    %usr_wg_TblYearNorm,
    usr_wg_TblCalLine, % 05, 06, 12
    usr_wg_TblCal_FlexLine, % 05, 06, 12
    usr_wg_HourType, % 05, 06
    usr_wg_TblCharge, % 05, 06, 12
    usr_wg_FeeType, % 05, 06, 12
    usr_wg_FeeTypeNoCoef,
    usr_wg_BadHourType,
    usr_wg_BadFeeType,
    usr_wg_SpecDep,
    %  06. Начисление больничных
    usr_wg_AvgWage,
    usr_wg_FeeTypeProp,
    wg_holiday,
    usr_wg_ExclDays,
    % 12. Начисление по-среднему
    usr_wg_TblChargeBonus,
    % section twg_struct
    %wg_holiday,
    wg_vacation_slice,
    wg_vacation_compensation,
    gd_const_budget,
    gd_const_AvgSalaryRB,
    %usr_wg_TblDayNorm,
    wg_job_ill_type
    ],
    working_directory(_, '..').
%%

%% dynamic state
:- ['kb/param_list'].
%%

%% flag
:- assertz(debug_mode).
%%

% ! при использовании в ТП Гедымин
% ! для begin & end debug mode section
% ! убрать символ процента из первой позиции
%*/ %%% end debug mode section

:- ps32k_lgt(64, 128, 64).

% section twg_avg_wage
% среднедневной заработок
% - для отпусков
% - для больничных
% - для начисления по-среднему
%

/* реализация - секция правил */

%% варианты правил расчета
%  - для отпусков
% [по расчетным месяцам, по среднечасовому]
wg_valid_rules([by_calc_month, by_avg_houre]).
%% варианты правил включения месяца в расчет
% табель за месяц покрывает график [по дням и часам, по часам, по дням]
wg_valid_rules([by_days_houres, by_houres, by_days]).
%% дополнительные правила для включения месяца в расчет
% [заработок за месяц не меньше любого из полных месяцев]
% (для одинаковых коэфициентов осовременивания)
wg_valid_rules([by_month_wage_any]).
% [заработок за месяц не меньше каждого из полных месяцев]
% (для одинаковых коэфициентов осовременивания)
wg_valid_rules([-by_month_wage_all]).
% [отсутствие в месяце плохих типов начислений и часов]
wg_valid_rules([-by_month_no_bad_type]).

%% варианты правил расчета
%  - для больничных
% [по расчетным дням, по расчетным дням со справкой]
wg_valid_rules([by_calc_days, by_calc_days_doc]).
% [от БПМ, по среднему заработку]
wg_valid_rules([by_budget, by_avg_wage]).
% [от ставки, по не полным месяцам]
wg_valid_rules([by_rate, -by_not_full]).
%% варианты правил для исключения дней
% [по табелю мастера, по табелю, по приказам]
wg_valid_rules([by_cal_flex, by_cal, by_orders]).
%% дополнительные правила для учета расчетных дней
% [хотя бы один месяц полный, все месяцы полные]
wg_valid_rules([by_calc_days_any, -by_calc_days_all]).

%% варианты правил полных месяцев
%  - для отпусков
% табель за месяц покрывает график [по дням и часам, по часам, по дням]
wg_full_month_rules([by_days_houres, by_houres, by_days]).

% правила запрещены по признаку
%  - для отпусков
wg_deny_flag_rules(flag_spec_dep, [by_days_houres, by_houres, by_days]).
wg_deny_flag_rules(flag_spec_dep, [by_month_wage_all]).
wg_deny_flag_rules(flag_spec_dep, [by_month_wage_any]).

% правило действительно
is_valid_rule(Scope, PK, Y-M, Rule) :-
    wg_valid_rules(ValidRules),
    member(Rule, ValidRules),
    \+ is_deny_rule(Scope, PK, Y-M, Rule),
    !.

% правило отвергается по признаку
is_deny_rule(Scope, PK, Y-M, Rule) :-
    get_flag_rule(Scope, PK, Y-M, Flag),
    wg_deny_flag_rules(Flag, FlagRules),
    member(Rule, FlagRules),
    !.
    
% получить признак
get_flag_rule(Scope, PK, _, Flag) :-
    Flag = flag_spec_dep,
    % последний график рабочего времени
    get_last_schedule(Scope, PK, ScheduleKey),
    % равен графику специального отдела
    get_spec_dep(Scope, PK, ScheduleKey),
    !.

% взять последний график рабочего времени
get_last_schedule(Scope, PK, ScheduleKey) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять график
    findall( ScheduleKey0,
             % для движения по сотруднику
             get_data(Scope, kb, usr_wg_MovementLine, [
                         fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                         fScheduleKey-ScheduleKey0]),
    % в список графиков
    ScheduleKeyList ),
    % определить последний график рабочего времени
    last(ScheduleKeyList, ScheduleKey),
    !.

% взять график специального отдела
get_spec_dep(Scope, PK, SpecDepKey) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные по графику специального отдела
    get_data(Scope, kb, usr_wg_SpecDep, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fID-SpecDepKey]),
    !.

/* реализация - расчет */

% среднедневной заработок
% Scope: wg_avg_wage_vacation ; wg_avg_wage_sick ; wg_avg_wage_avg
%        для отпусков ; для больничных ; для начисления по-среднему
avg_wage(Scope) :-
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [start-Scope-DT]),
    % шаблон первичного ключа
    PK = [pEmplKey-_, pFirstMoveKey-_],
    % для каждого первичного ключа расчета из входных параметров
    get_param_list(Scope, in, PK),
    % запустить цикл механизма подготовки данных
    engine_loop(Scope, in, PK),
    % выполнить расчет
    eval_avg_wage(Scope, PK),
    % найти альтернативу
    fail.
avg_wage(_) :-
    % больше альтернатив нет
    !.

% выполнить расчет
eval_avg_wage(Scope, PK) :-
    % взять локальное время
    get_local_date_time(DT1),
    % записать отладочную информацию
    new_param_list(Scope, debug, [begin-DT1|PK]),
    % удалить временные данные по расчету
    forall( get_param_list(Scope, temp, PK, Pairs),
            dispose_param_list(Scope, temp, Pairs) ),
    % вычислить среднедневной заработок по сотруднику
    calc_avg_wage(Scope, PK, AvgWage, Variant),
    % записать результат
    ret_avg_wage(Scope, PK, AvgWage, Variant),
    % взять локальное время
    get_local_date_time(DT2),
    % записать отладочную информацию
    new_param_list(Scope, debug, [end-DT2|PK]),
    !.

% записать результат
ret_avg_wage(Scope, PK, AvgWage, Variant) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять дополнительные данные из первого движения
    get_data(Scope, kb, usr_wg_MovementLine, [
                fEmplKey-EmplKey,
                fDocumentKey-FirstMoveKey, fFirstMoveKey-FirstMoveKey,
                fDateBegin-DateBegin, fMovementType-1,
                fListNumber-ListNumber
         ]),
    % для даты последнего приема на работу
    get_last_hire(Scope, PK, DateBegin),
    % записать выходные данные
    append(PK, [pListNumber-ListNumber,
                pAvgWage-AvgWage, pVariant-Variant],
            OutPairs),
    new_param_list(Scope, out, OutPairs),
    !.

% среднедневной заработок по сотруднику
calc_avg_wage(Scope, PK, AvgWage, Rule) :-
    % - для отпусков (по расчетным месяцам)
    Scope = wg_avg_wage_vacation, Rule = by_calc_month,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % проверка по табелю
    check_month_tab(Scope, PK, Periods),
            % если есть хотя бы один расчетный месяц
    once( ( once( get_month_incl(Scope, PK, _, _, _) ),
            % то проверка по заработку
            check_month_wage(Scope, PK, Periods)
            % иначе далее
          ; true )
        ),
    % проверка на отсутствие плохих типов начислений и часов
    check_month_no_bad_type(Scope, PK, Periods),
    % есть хотя бы один расчетный месяц
    once( get_month_incl(Scope, PK, _, _, _) ),
    % взять заработок
    findall( Wage,
               % за каждый расчетный месяц
             ( get_month_incl(Scope, PK, Y, M, _),
               % взять данные по заработку
               get_month_wage(Scope, PK, Y, M, _, Wage) ),
    % в список заработков
    Wages ),
    % итоговый заработок за расчетные месяцы
    sum_list(Wages, Amount),
    % количество расчетных месяцев
    length(Wages, Num),
    % среднемесячное количество календарных дней
    get_param(Scope, in, pAvgDays-AvgDays),
    % среднедневной заработок
    catch( AvgWage0 is Amount / Num / AvgDays, _, fail ),
    AvgWage is round(AvgWage0),
    !.
calc_avg_wage(Scope, PK, AvgWage, Rule) :-
    % - для отпусков (по среднечасовому)
    Scope = wg_avg_wage_vacation, Rule = by_avg_houre,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % взять заработок
    findall( Wage,
               % за каждый период проверки
             ( member(Y1-M1, Periods),
               % взять данные по заработку
               get_month_wage(Scope, PK, Y1, M1, _, Wage) ),
    % в список заработков
    Wages ),
    % итоговый заработок
    sum_list(Wages, Amount),
    % взять часы
    findall( THoures,
               % за период проверки
             ( member(Y2-M2, Periods),
               % взять данные по часам за месяц
               get_month_norm_tab(Scope, PK, Y2-M2, _, _, _, THoures) ),
    % в список часов
    Durations),
    % всего часов по табелю
    sum_list(Durations, TotalTab),
    % среднечасовой заработок
    catch( AvgHoureWage is Amount / TotalTab, _, fail ),
    % расчитать график за год
    calc_year_norm(Scope, PK, NormDays),
    % сумма дней и часов по графику
    sum_days_houres(NormDays, _, TotalNorm),
    % среднемесячное количество расчетных рабочих часов
    AvgMonthNorm is TotalNorm / 12,
    % среднемесячное количество календарных дней
    get_param(Scope, in, pAvgDays-AvgDays),
    % среднедневной заработок
    catch( AvgWage0 is AvgHoureWage * AvgMonthNorm / AvgDays, _, fail ),
    AvgWage is round(AvgWage0),
    !.
calc_avg_wage(Scope, PK, AvgWage, Rule) :-
    % - для больничных (по расчетным дням / со справкой)
    Scope = wg_avg_wage_sick, Rule1 = by_calc_days, Rule2 = by_calc_days_doc,
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % есть рабочие периоды
    \+ Periods = [],
    % если определяется вариант
    ( % по расчетным дням
      Rule = Rule1,
      % правило действительно
      is_valid_rule(Scope, PK, _, Rule1),
      % если есть требуемое количество месяцев
      get_param(Scope, run, pMonthQty-MonthQty),
      length(Periods, MonthQty),
      % и выполняется одно из правил по полноте месяца
      rule_month_days_sick(Scope, PK, Periods, _)
    ;
      % или по расчетным дням со справкой
      Rule = Rule2,
      % правило действительно
      is_valid_rule(Scope, PK, _, Rule2),
      % если есть признак Справка
      append(PK, [pIsAvgWageDoc-1], Pairs),
      get_param_list(Scope, run, Pairs),
      % и выполняется одно из правил по полноте месяца
      rule_month_days_sick(Scope, PK, Periods, _)
    ),
    % то выполнить расчет
    % взять заработок
    findall( Wage,
               % за каждый период проверки
             ( member(Y1-M1, Periods),
               % взять данные по заработку
               get_month_wage(Scope, PK, Y1, M1, _, Wage) ),
    % в список заработков
    Wages ),
    % итоговый заработок
    sum_list(Wages, Amount),
    % взять расчетные дни
    findall( CalcDays,
               % за каждый период проверки
             ( member(Y2-M2, Periods),
               % взять данные по расчетным дням
               get_month_days_sick(Scope, PK, Y2, M2, _, CalcDays, _, _) ),
    % в список расчетных дней
    CalcDaysList ),
    % всего расчетных дней
    sum_list(CalcDaysList, TotalCalcDays),
    % среднедневной заработок
    catch( AvgWage0 is Amount / TotalCalcDays, _, fail ),
    AvgWage is round(AvgWage0),
    !.
calc_avg_wage(Scope, PK, AvgWage, Rule) :-
    % - для больничных (от ставки без периодов со справкой)
    Scope = wg_avg_wage_sick, Rule = by_rate,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % не выполняется одно из правил по полноте месяца
    \+ rule_month_days_sick(Scope, PK, Periods, _),
    % есть признак Справка
    append(PK, [pIsAvgWageDoc-1], Pairs),
    get_param_list(Scope, run, Pairs),
    % расчет от ставки
    calc_avg_wage_sick(Scope, PK, Periods, AvgWage, Rule),
    !.
calc_avg_wage(Scope, PK, AvgWage, Rule) :-
    % - для больничных (от БПМ)
    Scope = wg_avg_wage_sick, Rule = by_budget,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % нет требуемого количества месяцев
    get_param(Scope, run, pMonthQty-MonthQty),
    \+ length(Periods, MonthQty),
    % расчет от БПМ при формировании структуры
    AvgWage is 0,
    !.
calc_avg_wage(Scope, PK, AvgWage, Rule) :-
    % - для больничных (по среднему заработку)
    Scope = wg_avg_wage_sick, Rule = by_avg_wage,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % есть требуемое количество месяцев
    get_param(Scope, run, pMonthQty-MonthQty),
    length(Periods, MonthQty),
    % расчет по среднему заработку
    calc_avg_wage_sick(Scope, PK, Periods, AvgWage, Rule),
    !.
calc_avg_wage(Scope, PK, AvgWage, Rule) :-
    % - для больничных (от ставки / по не полным месяцам)
    Scope = wg_avg_wage_sick, Rule1 = by_rate, Rule2 = by_not_full,
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % расчет по разным вариантам
    % от ставки
    once( ( calc_avg_wage_sick(Scope, PK, Periods, AvgWage1, Rule1)
          ; AvgWage1 = 0 )
        ),
    % по не полным месяцам
    once( ( calc_avg_wage_sick(Scope, PK, Periods, AvgWage2, Rule2)
          ; AvgWage2 = 0 )
        ),
    \+ [AvgWage1, AvgWage2] = [0, 0],
    % выбор варианта расчета
    ( AvgWage1 >= AvgWage2,
      % от ставки
      Rule = Rule1,
      AvgWage = AvgWage1
    ;
      % по не полным месяцам
      Rule = Rule2,
      AvgWage = AvgWage2 ),
    !.
calc_avg_wage(Scope, PK, AvgWage, Variant) :-
    % - для начисления по-среднему (по часам или дням)
    Scope = wg_avg_wage_avg,
    % подготовка временных данных для расчета
    prep_avg_wage(Scope, PK, Periods),
    % взять заработок
    findall( Wage1,
               % за каждый период проверки
             ( member(Y1-M1, Periods),
               % взять данные по заработку
               get_month_wage(Scope, PK, Y1, M1, _, Wage1),
               % где значение больше 0
               Wage1 > 0 ),
    % в список заработков
    Wages ),
    % есть требуемое количество месяцев
    get_param(Scope, run, pMonthQty-MonthQty),
    length(Wages, MonthQty),
    % итоговый заработок
    sum_list(Wages, Amount),
    % взять часы
    findall( THoures,
               % за период проверки
             ( member(Y2-M2, Periods),
               % взять данные по часам за месяц
               get_month_norm_tab(Scope, PK, Y2-M2, _, _, _, THoures),
               % для заработка
               get_month_wage(Scope, PK, Y2, M2, _, Wage2),
               % значение которого больше 0
               Wage2 > 0 ),
    % в список часов
    Durations),
    % всего часов по табелю
    sum_list(Durations, TotalTab),
    % среднечасовой заработок
    catch( AvgHoureWage is Amount / TotalTab, _, fail ),
    get_param(Scope, run, pCalcByHoure-CalcByHoure),
    % расчет по часам или дням
    ( CalcByHoure = 1, AvgWage is round(AvgHoureWage), Variant = avg_houre
    ; AvgWage is round(8 * AvgHoureWage), Variant = avg_day
    ),
    !.
calc_avg_wage(Scope, PK, AvgWage, Variant) :-
    % - для начисления по-среднему (нужно больше месяцев)
    Scope = wg_avg_wage_avg,
    % периоды для проверки
    get_periods(Scope, PK, [Y-M|_]),
    atom_date(FirstDate, date(Y, M, 1)),
    % для даты последнего приема на работу
    get_last_hire(Scope, PK, DateBegin),
    % если дата последнего приема на работу меньше первой даты расчета
    DateBegin @< FirstDate,
    % и не превышен лимит
    get_param_list(Scope, run, [pMonthLimitQty-MonthLimitQty, pMonthBefore-MonthBefore]),
    \+ MonthBefore > MonthLimitQty,
    % то для расчета нужно больше месяцев
    AvgWage = 0, Variant = need_more,
    !.
calc_avg_wage(Scope, PK, AvgWage, Variant) :-
    % - для начисления по-среднему (нет требуемого количества месяцев)
    Scope = wg_avg_wage_avg,
    % периоды для проверки
    get_periods(Scope, PK, [Y-M|_]),
    atom_date(FirstDate, date(Y, M, 1)),
    % взять дату последнего приема на работу
    get_last_hire(Scope, PK, DateBegin),
    % если дата последнего приема на работу не меньше первой даты расчета
    \+ DateBegin @< FirstDate,
    % то для расчета нет требуемого количества месяцев
    AvgWage = 0, Variant = no_data,
    !.

% выбор варианта расчета среднедневного заработка
% - для больничных
calc_avg_wage_sick(Scope, PK, Periods, AvgWage, Rule) :-
    % по среднему заработку
    Rule = by_avg_wage,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные по среднедневному заработку
    findall( AvgSumma,
             ( member(Y-M, Periods),
               get_data(Scope, kb, usr_wg_AvgWage, [
                           fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                           fCalYear-Y, fCalMonth-M, fAvgSumma-AvgSumma])
             ),
    % в список среднедневных заработков
    AvgSummaList),
    % максимальный среднедневной заработок
    max_list(AvgSummaList, MaxAvgSumma),
    AvgWage is round(MaxAvgSumma),
    !.
calc_avg_wage_sick(Scope, PK, Periods, AvgWage, Rule) :-
    % от ставки
    Rule = by_rate,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % взять расчетную дату
    append(PK, [pDateCalc-DateCalc], Pairs),
    get_param_list(Scope, run, Pairs),
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные по ставке
    findall( PayFormKey0-SalaryKey0-TSalary0-AvgWageRate0,
               % из данных по движению
             ( get_data(Scope, kb, usr_wg_MovementLine, [
                         fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                         fDateBegin-DateBegin,
                         fPayFormKey-PayFormKey0, fSalaryKey-SalaryKey0,
                         fTSalary-TSalary0, fAvgWageRate-AvgWageRate0 ]),
               % где дата меньше или равна расчетной
               DateBegin @=< DateCalc ),
    % в список ставок
    RateList ),
    % взять последние данные по ставке
    last(RateList, PayFormKey-SalaryKey-TSalary-AvgWageRate),
      % если форма оплаты оклад, то расчет по тарифному окладу
    ( PayFormKey = SalaryKey,
      % сформировать список заработков по тарифному окладу
      findall( TSalary, member(_-_, Periods), Wages ),
      % итоговый заработок
      sum_list(Wages, Amount),
      % сформировать список расчетных дней по календарным дням месяца
      findall( CalcDays,
               ( member(Y-M, Periods), month_days(Y, M, CalcDays) ),
      CalcDaysList ),
      % всего расчетных дней
      sum_list(CalcDaysList, TotalCalcDays),
      % среднедневной заработок
      catch( AvgWage0 is Amount / TotalCalcDays, _, fail ),
      AvgWage is round(AvgWage0)
    ;
      % иначе, расчет от часовой тарифной ставки
      AvgWage is round(AvgWageRate) ),
    !.
calc_avg_wage_sick(Scope, PK, Periods, AvgWage, Rule) :-
    % по не полным месяцам
    Rule = by_not_full,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % если есть требуемое количество месяцев
    get_param(Scope, run, pMonthQty-MonthQty),
    length(Periods, MonthQty),
    % то выполнить расчет
    % взять заработок
    findall( Wage,
               % за каждый период проверки
             ( member(Y1-M1, Periods),
               % взять данные по заработку
               get_month_wage(Scope, PK, Y1, M1, _, Wage) ),
    % в список заработков
    Wages ),
    % итоговый заработок
    sum_list(Wages, Amount),
    % взять расчетные дни
    findall( CalcDays,
               % за каждый период проверки
             ( member(Y2-M2, Periods),
               % взять данные по расчетным дням
               get_month_days_sick(Scope, PK, Y2, M2, _, CalcDays, _, _) ),
    % в список расчетных дней
    CalcDaysList ),
    % всего расчетных дней
    sum_list(CalcDaysList, TotalCalcDays),
    % среднедневной заработок
    catch( AvgWage0 is Amount / TotalCalcDays, _, fail ),
    AvgWage is round(AvgWage0),
    !.

% правила для учета расчетных дней
% - для больничных
rule_month_days_sick(Scope, PK, Periods, Rule) :-
    Rule = by_calc_days_any,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % есть хотя бы один полный месяц
    member(Y-M, Periods),
    get_month_days_sick(Scope, PK, Y, M, _, _, IsFullMonth, IsSpecMonth),
    ( IsFullMonth = 1 ; IsSpecMonth = 1 ),
    !.
rule_month_days_sick(Scope, PK, Periods, Rule) :-
    Rule = by_calc_days_all,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % есть рабочие периоды
    \+ Periods = [],
    % все месяцы полные
    is_full_all_month_sick(Scope, PK, Periods),
    !.

% все месяцы полные
% - для больничных
is_full_all_month_sick(_, _, []):-
    % все месяцы проверены
    !.
is_full_all_month_sick(Scope, PK, [Y-M|Periods]) :-
    % есть данные по расчетным дням для полного месяца
    get_month_days_sick(Scope, PK, Y, M, _, _, IsFullMonth, IsSpecMonth),
    ( IsFullMonth = 1 ; IsSpecMonth = 1 ),
    !,
    % проверить остальные месяцы
    is_full_all_month_sick(Scope, PK, Periods).

% подготовка временных данных для расчета
prep_avg_wage(Scope, PK, Periods) :-
    % формирование временных данных по графику работы
    make_schedule(Scope, PK),
    % периоды для проверки
    get_periods(Scope, PK, Periods),
    % добавление временных данных по расчету дней и часов
    add_month_norm_tab(Scope, PK, Periods),
    % подготовка дополнительных временных данных
    prep_avg_wage_extra(Scope, PK, Periods),
    % добавление временных данных по расчету заработков
    add_month_wage(Scope, PK, Periods),
    !.

% подготовка дополнительных временных данных
prep_avg_wage_extra(Scope, _, _) :-
    % - для отпусков
    Scope = wg_avg_wage_vacation,
    !.
prep_avg_wage_extra(Scope, PK, Periods) :-
    % - для больничных
    Scope = wg_avg_wage_sick,
    % добавление временных данных по расчетным дням
    add_month_days_sick(Scope, PK, Periods),
    !.
prep_avg_wage_extra(Scope, PK, _) :-
    % - для начисления по-среднему
    Scope = wg_avg_wage_avg,
    % подготовка фактов по начислениям
    prep_TblCharge(Scope, PK),
    !.

% подготовка фактов по начислениям
prep_TblCharge(Scope, PK) :-
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    PredName/Arity = usr_wg_TblCharge/10,
    once( gd_pl_ds(Scope, kb, PredName, Arity, _) ),
    Args = [EmplKey, FirstMoveKey, _, _, DateBegin,
            Debit, FeeTypeKey, DOW, HOW, PayPeriod],
    Term =.. [PredName|Args],
    catch( Term, _, fail ), \+ PayPeriod < 2,
    Debit1 is round(Debit / PayPeriod),
    % добавление фактов по начислениям
    add_TblCharge(PayPeriod, [PredName, EmplKey, FirstMoveKey],
                    DateBegin, [Debit1, FeeTypeKey], DOW, HOW),
    fail.
prep_TblCharge(Scope, PK) :-
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    PredName/Arity = usr_wg_TblChargeBonus/8,
    once( gd_pl_ds(Scope, kb, PredName, Arity, _) ),
    PredName1/Arity1 = usr_wg_TblCharge/10,
    once( gd_pl_ds(Scope, kb, PredName1, Arity1, _) ),
    Args = [EmplKey, FirstMoveKey, _, _, DateBegin,
            Debit, FeeTypeKey, PayPeriod],
    Term =.. [PredName|Args],
    catch( Term, _, fail ), \+ PayPeriod < 2,
    Debit1 is round(Debit / PayPeriod),
    % добавление фактов по начислениям
    add_TblCharge(PayPeriod, [PredName1, EmplKey, FirstMoveKey],
                    DateBegin, [Debit1, FeeTypeKey], 0, 0),
    fail.
prep_TblCharge(_, _) :-
    !.

% добавление фактов по начислениям
add_TblCharge(0, _, _, _, _, _) :-
    !.
add_TblCharge(PayPeriod, List1, DateBegin, List3, DOW, HOW) :-
    atom_date(DateBegin, date(CalYear, CalMonth, _)),
    List2 = [CalYear, CalMonth, DateBegin],
    append([List1, List2, List3, [DOW, HOW, 1]], List),
    Term =.. List, assertz( Term ),
    PayPeriod1 is PayPeriod - 1,
    date_add(DateBegin, 1, month, DateBegin1),
    !,
    add_TblCharge(PayPeriod1, List1, DateBegin1, List3, 0, 0).

% формирование временных данных по графику работы
make_schedule(Scope, PK) :-
    % временные данные по графику работы уже есть
    get_param_list(Scope, temp, [pScheduleKey-_|PK]),
    !.
make_schedule(Scope, PK) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные по движению
    findall( Date-ScheduleKey,
             get_data(Scope, kb, usr_wg_MovementLine, [
                         fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                         fDateBegin-Date, fScheduleKey-ScheduleKey]),
    MoveList ),
    % взять дату ограничения расчета
    get_param_list(Scope, run, [pDateCalcTo-DateCalcTo|PK]),
    % добавить временные данные по графику работы
    add_schedule(Scope, PK, MoveList, DateCalcTo),
    !.

% добавить временные данные по графику работы
add_schedule(_, _, [], _) :-
    !.
add_schedule(Scope, PK, [DateFrom-ScheduleKey], DateCalcTo) :-
    append(PK,
            [pDateFrom-DateFrom, pDateTo-DateCalcTo, pScheduleKey-ScheduleKey],
                Pairs),
    new_param_list(Scope, temp, Pairs),
    !.
add_schedule(Scope, PK, [DateFrom-ScheduleKey, DateTo-ScheduleKey1 | MoveList], DateCalcTo) :-
    append(PK,
            [pDateFrom-DateFrom, pDateTo-DateTo, pScheduleKey-ScheduleKey],
                Pairs),
    new_param_list(Scope, temp, Pairs),
    !,
    add_schedule(Scope, PK, [DateTo-ScheduleKey1 | MoveList], DateCalcTo).

% периоды для проверки
get_periods(Scope, PK, Periods) :-
    % взять временные данные по списку периодов
    get_param_list(Scope, temp, [pPeriods-Periods|PK]),
    !.
get_periods(Scope, PK, Periods) :-
    % взять даты ограничения расчета
    append(PK, [pDateCalcFrom-DateFrom, pDateCalcTo-DateTo], Pairs1),
    get_param_list(Scope, run, Pairs1),
    % сформировать список периодов
    make_periods(Scope, PK, DateFrom, DateTo, Periods),
    % добавить временные данные по списку периодов
    append(PK, [pPeriods-Periods], Pairs2),
    new_param_list(Scope, temp, Pairs2),
    !.

% сформировать список периодов
make_periods(_, _, DateFrom, DateTo, []) :-
    DateFrom @>= DateTo,
    !.
make_periods(Scope, PK, DateFrom, DateTo, [Y-M|Periods]) :-
    atom_date(DateFrom, date(Y, M, _)),
    % период является рабочим
    is_work_period(Scope, PK, Y-M),
    % добавить месяц
    date_add(DateFrom, 1, month, DateFrom1),
    !,
    make_periods(Scope, PK, DateFrom1, DateTo, Periods).
make_periods(Scope, PK, DateFrom, DateTo, Periods) :-
    % добавить месяц
    date_add(DateFrom, 1, month, DateFrom1),
    !,
    make_periods(Scope, PK, DateFrom1, DateTo, Periods).

%  период является рабочим
is_work_period(Scope, PK, Y-M) :-
    % календарных дней в месяце
    month_days(Y, M, MonthDays),
    % последняя дата месяца
    atom_date(LastMonthDate, date(Y, M, MonthDays)),
    % определить дату последнего приема на работу
    get_last_hire(Scope, PK, DateIn),
    % если дата приема на работу не больше последней даты месяца
    DateIn @=< LastMonthDate,
    % то период является рабочим
    !.

% взять дату последнего приема на работу
get_last_hire(Scope, PK, DateIn) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять даты
    findall( DateIn0,
             % для первого движения по типу 1 (прием на работу)
             get_data(Scope, kb, usr_wg_MovementLine, [
                         fEmplKey-EmplKey,
                         fDocumentKey-FirstMoveKey, fFirstMoveKey-FirstMoveKey,
                         fDateBegin-DateIn0, fMovementType-1 ]),
    % в список дат приема на работу
    DateInList ),
    % определить дату последнего приема на работу
    last(DateInList, DateIn),
    !.

% добавление временных данных по расчету дней и часов
add_month_norm_tab(_, _, []):-
    % больше месяцев для проверки нет
    !.
add_month_norm_tab(Scope, PK, [Y-M|Periods]) :-
    % проверить данные по графику и табелю за месяц
    get_month_norm_tab(Scope, PK, Y-M, _, _, _, _),
    !,
    % проверить остальные месяцы
    add_month_norm_tab(Scope, PK, Periods).
add_month_norm_tab(Scope, PK, [_|Periods]) :-
    !,
    % проверить остальные месяцы
    add_month_norm_tab(Scope, PK, Periods).

% добавление временных данных по расчету заработков
add_month_wage(_, _, []):-
    % больше месяцев для проверки нет
    !.
add_month_wage(Scope, PK, [Y-M|Periods]) :-
    % проверить данные по заработку
    get_month_wage(Scope, PK, Y, M, _, _),
    !,
    % проверить остальные месяцы
    add_month_wage(Scope, PK, Periods).
add_month_wage(Scope, PK, [_|Periods]) :-
    !,
    % проверить остальные месяцы
    add_month_wage(Scope, PK, Periods).

% взять данные по заработку за месяц
get_month_wage(Scope, PK, Y, M, MonthModernCoef, ModernWage) :-
    % - для отпусков
    Scope = wg_avg_wage_vacation,
    % взять из временных параметров данные по заработку
    append(PK, [pYM-Y-M, pModernCoef-MonthModernCoef, pModernWage-ModernWage],
            Pairs),
    get_param_list(Scope, temp, Pairs),
    !.
get_month_wage(Scope, PK, Y, M, MonthModernCoef, ModernWage) :-
    % - для отпусков
    Scope = wg_avg_wage_vacation,
    % расчитать заработок за месяц
    cacl_month_wage(Scope, PK, Y, M, Wage, MonthModernCoef, ModernWage, SalaryOld, SalaryNew),
    % записать во временные параметры данные по заработку
    append(PK, [pYM-Y-M,
                pWage-Wage, pModernCoef-MonthModernCoef, pModernWage-ModernWage,
                pSalaryOld-SalaryOld, pSalaryNew-SalaryNew],
            Pairs),
    new_param_list(Scope, temp, Pairs),
    !.
get_month_wage(Scope, PK, Y, M, 1.0, Wage) :-
    % - для больничных
    Scope = wg_avg_wage_sick,
    % взять из временных параметров данные по заработку
    append(PK, [pYM-Y-M, pWage-Wage],
            Pairs),
    get_param_list(Scope, temp, Pairs),
    !.
get_month_wage(Scope, PK, Y, M, 1.0, Wage) :-
    % - для больничных
    Scope = wg_avg_wage_sick,
    % расчитать заработок за месяц
    cacl_month_wage_sick(Scope, PK, Y, M, Wage),
    % записать во временные параметры данные по заработку
    append(PK, [pYM-Y-M, pWage-Wage], Pairs),
    new_param_list(Scope, temp, Pairs),
    !.
get_month_wage(Scope, PK, Y, M, 1.0, Wage) :-
    % - для начисления по-среднему
    Scope = wg_avg_wage_avg,
    % взять из временных параметров данные по заработку
    append(PK, [pYM-Y-M, pWage-Wage],
            Pairs),
    get_param_list(Scope, temp, Pairs),
    !.
get_month_wage(Scope, PK, Y, M, 1.0, Wage) :-
    % - для начисления по-среднему
    Scope = wg_avg_wage_avg,
    % расчитать заработок за месяц
    cacl_month_wage_avg(Scope, PK, Y, M, Wage),
    % записать во временные параметры данные по заработку
    append(PK, [pYM-Y-M, pWage-Wage], Pairs),
    new_param_list(Scope, temp, Pairs),
    !.

% расчитать заработок за месяц
% - для отпусков
cacl_month_wage(Scope, PK, Y, M, Wage, MonthModernCoef, ModernWage, SalaryOld, SalaryNew) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % параметры выбора начислений
    member(ChargeOption, [tbl_charge, dbf_sums]),
    % взять начисления
    findall( Debit-ModernCoef-SalaryOld0-SalaryNew0,
          % для начисления по одному из параметров
          % где дата совпадает с проверяемым месяцем
          ( usr_wg_TblCharge_mix(Scope, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fCalYear-Y, fCalMonth-M, fDateBegin-TheDay,
                fDebit-Debit, fFeeTypeKey-FeeTypeKey ],
                                    ChargeOption),
          % и соответствующего типа
          once( ( var(FeeTypeKey)
                ; get_data(Scope, kb, usr_wg_FeeType, [
                            fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                            fFeeTypeKey-FeeTypeKey ])
                )
              ),
          % с коэффициентом осовременивания
          get_modern_coef(Scope, PK, TheDay, FeeTypeKey, ModernCoef, SalaryOld0, SalaryNew0)
          ),
    % в список начислений
    Debits ),
    % проверить список начислений
    \+ Debits = [],
    % всего за месяц
    sum_month_debit(Debits, Wage, ModernWage0),
    % средний за месяц коэффициент осовременивания
    catch( MonthModernCoef0 is ModernWage0 / Wage, _, fail),
    to_currency(MonthModernCoef0, MonthModernCoef, 2),
    % осовремененный заработок
    ModernWage is round(Wage * MonthModernCoef),
    % старый и новый оклады
    ( setof( SalaryOld0-SalaryNew0,
            Debit ^ ModernCoef ^ member(Debit-ModernCoef-SalaryOld0-SalaryNew0, Debits),
            [SalaryOld-SalaryNew]
           )
    ; [SalaryOld-SalaryNew] = [0-0]
    ),
    !.

% итого зарплата и осовремененная зарплата за месяц
% - для отпусков
sum_month_debit(Debits, Wage, ModernWage) :-
    sum_month_debit(Debits, Wage, ModernWage, 0, 0),
    !.
%
sum_month_debit([], Wage, ModernWage, Wage, ModernWage) :-
    !.
sum_month_debit([Debit-ModernCoef-_-_ | Debits], Wage, ModernWage, Wage0, ModernWage0) :-
    Wage1 is Wage0 + Debit,
    ModernWage1 is ModernWage0 + Debit * ModernCoef,
    !,
    sum_month_debit(Debits, Wage, ModernWage, Wage1, ModernWage1).

% коэффициент осовременивания
get_modern_coef(Scope, PK, _, FeeTypeKey, 1.0, 0, 0) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % проверить тип начисления на исключение для осовременивания
    get_data(Scope, kb, usr_wg_FeeTypeNoCoef, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fFeeTypeKeyNoCoef-FeeTypeKey ]),
    !.
get_modern_coef(Scope, PK, TheDay, _, ModernCoef, SalaryOld, SalaryNew) :-
    % взять параметр коэфициента и дату ограничения расчета
    append(PK, [pDateCalcTo-DateTo, pCoefOption-CoefOption], Pairs),
    get_param_list(Scope, run, Pairs),
    % сформировать дату ограничения выплаты
    date_add(DateTo, 1, month, DateTo1),
    % сформировать список движений дата-сумма
    findall( Date-Amount,
             get_modern_coef_data(PK, Scope, Date, Amount, CoefOption, DateTo1),
    Movements ),
    % вычислить коэффициент
    calc_modern_coef(TheDay, Movements, ModernCoef, SalaryOld, SalaryNew),
    !.

% взять данные для расчета коэфициента осовременивания
%
get_modern_coef_data(PK, Scope, Date, FCRateSum, CoefOption, DateTo) :-
    % справочник базовых величин - тарифная ставка 1-го разряда
    nonvar(CoefOption), CoefOption = fc_fcratesum,
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные из справочника по ставке
    get_data(Scope, kb, usr_wg_FCRate, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fDate-Date, fFCRateSum-FCRateSum ]),
    % где дата меньше расчетной
    Date @< DateTo.
%
get_modern_coef_data(PK, Scope, DateBegin, Rate, CoefOption, DateTo) :-
    % движение - тарифная ставка 1-го разряда
    nonvar(CoefOption), CoefOption = ml_rate,
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные из движения по ставке
    get_data(Scope, kb, usr_wg_MovementLine, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fDateBegin-DateBegin, fRate-Rate ]),
    % где дата меньше расчетной
    DateBegin @< DateTo.
%
get_modern_coef_data(PK, Scope, DateBegin, MSalary, CoefOption, DateTo) :-
    % движение - оклад
    nonvar(CoefOption), CoefOption = ml_msalary,
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные из движения по окладу
    get_data(Scope, kb, usr_wg_MovementLine, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fDateBegin-DateBegin, fMSalary-MSalary ]),
    % где дата меньше расчетной
    DateBegin @< DateTo.

% вычислить коэффициент
calc_modern_coef(_, [ _-Rate | [] ], 1.0, Rate, Rate) :-
    % если последнее движение, то коэффициент 1
    !.
calc_modern_coef(TheDay, [ Date1-Rate1, Date2-Rate2 | Movements ], ModernCoef, Rate1, RateLast) :-
    % если проверяемая дата больше или равна даты текущего движения
    TheDay @>= Date1,
    % и меньше даты следующего движения
    TheDay @< Date2,
    % то взять последнюю ставку из следующего и всех оставшихся движений
    last([Date2-Rate2 | Movements], _-RateLast),
    % и вычислить коэффициент для текущего движения
    catch( ModernCoef0 is RateLast / Rate1, _, fail),
    ( ModernCoef0 < 1.0, ModernCoef = 1.0 ; ModernCoef = ModernCoef0 ),
    !.
calc_modern_coef(TheDay, [ _ | Movements ], ModernCoef, Rate, RateLast) :-
    % проверить для остальных движений
    !,
    calc_modern_coef(TheDay, Movements, ModernCoef, Rate, RateLast).

% расчитать заработок за месяц
% - для больничных
cacl_month_wage_sick(Scope, PK, Y, M, Wage) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % параметры выбора начислений
    member(ChargeOption, [tbl_charge, dbf_sums]),
    % взять начисления
    findall( Debit-FeeTypeKey,
          % для начисления по одному из параметров
          % где дата совпадает с проверяемым месяцем
          ( usr_wg_TblCharge_mix(Scope, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fCalYear-Y, fCalMonth-M, fDateBegin-_,
                fDebit-Debit, fFeeTypeKey-FeeTypeKey ],
                                    ChargeOption),
          % и соответствующего типа
          once( ( var(FeeTypeKey)
                ; get_data(Scope, kb, usr_wg_FeeType, [
                            fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                            fFeeTypeKey-FeeTypeKey ])
                )
              )
          ),
    % в список начислений
    Debits ),
    % проверить список начислений
    \+ Debits = [],
    % всего за месяц
    sum_month_debit_sick(Scope, PK, Y, M, Debits, Wage),
    !.
cacl_month_wage_sick(_, _, _, _, 0.0) :-
    !.
    
% итого зарплата за месяц
% - для больничных
sum_month_debit_sick(Scope, PK, Y, M, Debits, Wage) :-
    % расчитать сумму начислений
    sum_month_debit_sick(Scope, PK, Y, M, Debits, Wage, 0.0),
    !.
%
sum_month_debit_sick(_, _, _, _, [], Wage, Wage) :-
    !.
sum_month_debit_sick(Scope, PK, Y, M, [Debit-FeeTypeKey | Debits], Wage, Wage0) :-
    nonvar(FeeTypeKey),
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % тип начисления для пропорционального расчета
    once( get_data(Scope, kb, usr_wg_FeeTypeProp, [
                    fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                    fFeeTypeKeyProp-FeeTypeKey ]) ),
    % взять коэфициент для пропорционального начисления
    get_prop_coef(Scope, PK, Y, M, PropCoef),
    % пропорциональный расчет
    Debit1 is round(Debit * PropCoef),
    Wage1 is Wage0 + Debit1,
    !,
    sum_month_debit_sick(Scope, PK, Y, M, Debits, Wage, Wage1).
sum_month_debit_sick(Scope, PK, Y, M, [Debit-_ | Debits], Wage, Wage0) :-
    % обычный расчет
    Wage1 is Wage0 + Debit,
    !,
    sum_month_debit_sick(Scope, PK, Y, M, Debits, Wage, Wage1).

% взять коэфициент для пропорционального начисления
get_prop_coef(Scope, PK, Y, M, PropCoef) :-
    % взять данные по графику и табелю за месяц
    get_month_norm_tab(Scope, PK, Y-M, NDays, TDays, NHoures, THoures),
    % расчитать коэфициент для пропорционального начисления
    calc_prop_coef(TDays, NDays, THoures, NHoures, PropCoef),
    !.

% расчитать коэфициент для пропорционального начисления
calc_prop_coef(TabDays, NormDays, _, _, 1.0) :-
    TabDays >= NormDays,
    !.
calc_prop_coef(_, _, TabHoures, NormHoures, 1.0) :-
    TabHoures >= NormHoures,
    !.
calc_prop_coef(TabDays, NormDays, TabHoures, NormHoures, PropCoef) :-
    catch( PropCoef1 is TabDays / NormDays, _, fail ),
    catch( PropCoef2 is TabHoures / NormHoures, _, fail ),
    PropCoef is max(PropCoef1, PropCoef2),
    \+ PropCoef > 1.0,
    !.
calc_prop_coef(_, _, _, _, 1.0) :-
    !.

% добавление временных данных по расчетным дням
% - для больничных
add_month_days_sick(_, _, []):-
    % больше месяцев для проверки нет
    !.
add_month_days_sick(Scope, PK, [Y-M|Periods]) :-
    % проверить данные по расчетным дням
    get_month_days_sick(Scope, PK, Y, M, _, _, _, _),
    !,
    % проверить остальные месяцы
    add_month_days_sick(Scope, PK, Periods).
add_month_days_sick(Scope, PK, [_|Periods]) :-
    !,
    % проверить остальные месяцы
    add_month_days_sick(Scope, PK, Periods).

% взять данные по расчетным дням
% - для больничных
get_month_days_sick(Scope, PK, Y, M, MonthDays, CalcDays, IsFullMonth, IsSpecMonth) :-
    % взять из временных параметров данные по расчетным дням
    append(PK, [pYM-Y-M, pRule-_,
                pMonthDays-MonthDays, pExclDays-_,
                pCalcDays-CalcDays, pIsFullMonth-IsFullMonth,
                pIsSpecMonth-IsSpecMonth],
            Pairs),
    get_param_list(Scope, temp, Pairs),
    !.
get_month_days_sick(Scope, PK, Y, M, MonthDays, CalcDays, IsFullMonth, IsSpecMonth) :-
    % календарных дней в месяце
    month_days(Y, M, MonthDays),
    % исключаемые из месяца дни по правилам
    excl_month_days_sick(Scope, PK, Y, M, ExclDays0, SpecExclDays, Variant),
    % исключаемые из первого месяца работы дни
    excl_first_month_days_sick(Scope, PK, Y, M, ExclDays1),
    % исключаемые дни
    ExclDays is ExclDays0 + ExclDays1,
    % расчетные дни
    CalcDays is MonthDays - ExclDays,
    % полнота месяца
    ( CalcDays = MonthDays -> IsFullMonth = 1 ; IsFullMonth = 0 ),
    % все дни для исключения специальные
    ( ExclDays = SpecExclDays -> IsSpecMonth = 1 ; IsSpecMonth = 0 ),
    % записать во временные параметры данные по расчетным дням
    append(PK, [pYM-Y-M, pRule-Variant,
                pMonthDays-MonthDays, pExclDays-ExclDays,
                pCalcDays-CalcDays, pIsFullMonth-IsFullMonth,
                pIsSpecMonth-IsSpecMonth],
            Pairs),
    new_param_list(Scope, temp, Pairs),
    !.

% исключаемые из месяца дни
% - для больничных
excl_month_days_sick(Scope, PK, Y, M, ExclDays, SpecExclDays, Rule) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % параметры выбора табеля
    member(TabelOption-Rule, [tbl_cal_flex-by_cal_flex, tbl_cal-by_cal]),
    % есть данные в табеле
    usr_wg_TblCalLine_mix(Scope, PK, Y-M, _, _, _, _, TabelOption),
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % взять данные из табеля
    findall( ExclType,
              % для проверяемого месяца
            ( usr_wg_TblCalLine_mix(Scope, PK, Y-M, _, _, _, HoureType, TabelOption),
              % с контролем наличия типа часов
              HoureType > 0,
              % по типу часов для исключения из расчета
              once( get_data(Scope, kb, usr_wg_HourType, [
                                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                                fID-HoureType, fExcludeForSickList-1,
                                fExclType-ExclType] ) )
            ),
    % в список дней для исключения
    ExclDaysList),
    % проверить список дней для исключения
    \+ ExclDaysList = [],
    % всего дней для исключения
    length(ExclDaysList, ExclDays),
    % сбор специальных исключаемых дней
    findall( SpecExclType,
            ( member(SpecExclType, ExclDaysList),
              memberchk(SpecExclType, ["kind_day"]) ),
    SpecExclDaysList),
    % всего специальных дней для исключения
    length(SpecExclDaysList, SpecExclDays),
    !.
excl_month_days_sick(Scope, PK, Y, M, ExclDays, SpecExclDays, Rule) :-
    Rule = by_orders,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % нет данных в табеле
    \+ usr_wg_TblCalLine_mix(Scope, PK, Y-M, _, _, _, _, tbl_cal_flex),
    \+ usr_wg_TblCalLine_mix(Scope, PK, Y-M, _, _, _, _, tbl_cal),
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные
    findall( FromDate-ToDate-ExclType-ExclWeekDay,
             % из приказов по дням исключения
             get_data(Scope, kb, usr_wg_ExclDays, [
                        fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                        fExclType-ExclType, fExclWeekDay-ExclWeekDay,
                        fFromDate-FromDate, fToDate-ToDate] ),
    % в список периодов для исключения
    ExclPeriods),
    % сбор исключаемых дней по списку периодов
    collect_excl_days(ExclPeriods, Y, M, [], LogDays, []),
    % всего дней для исключения
    length(LogDays, ExclDays),
    \+ ExclDays =:= 0,
    % сбор специальных исключаемых дней по списку периодов
    collect_excl_days(ExclPeriods, Y, M, [], LogSpecDays, ["KINDDAYLINE"]),
    % всего специальных дней для исключения
    length(LogSpecDays, SpecExclDays),
    !.
excl_month_days_sick(_, _, _, _, 0, 0, none) :-
    !.

% сбор исключаемых дней по списку периодов
collect_excl_days([], _, _, LogDays, LogDays, _) :-
    !.
collect_excl_days([ExclPeriod|ExclPeriods], Y, M, LogDays0, LogDays2, SpecList) :-
    % сбор исключаемых дней за период
    collect_excl_days(ExclPeriod, Y, M, LogDays0, LogDays1, SpecList),
    !,
    collect_excl_days(ExclPeriods, Y, M, LogDays1, LogDays2, SpecList).

% сбор исключаемых дней за период
collect_excl_days(FromDate-ToDate-_-_, _, _, LogDays, LogDays, _) :-
    FromDate @> ToDate,
    !.
collect_excl_days(FromDate0-ToDate-ExclType-ExclWeekDay, Y, M, LogDays0, LogDays2, SpecList) :-
    \+ atom_date(FromDate0, date(Y, M, _)),
    date_add(FromDate0, 1, day, FromDate1),
    !,
    collect_excl_days(FromDate1-ToDate-ExclType-ExclWeekDay, Y, M, LogDays0, LogDays2, SpecList).
collect_excl_days(FromDate0-ToDate-ExclType-ExclWeekDay, Y, M, LogDays0, LogDays2, SpecList) :-
    % добавление дня для исключения в журнал
    ( ( SpecList = [] ; memberchk(ExclType, SpecList) )
      -> add_excl_day(FromDate0-ExclType-ExclWeekDay, LogDays0, LogDays1)
    ; true ),
    date_add(FromDate0, 1, day, FromDate1),
    !,
    collect_excl_days(FromDate1-ToDate-ExclType-ExclWeekDay, Y, M, LogDays1, LogDays2, SpecList).

% добавление дня для исключения в журнал
add_excl_day(TheDate-_-_, LogDays, LogDays) :-
    % при наличии даты в журнале
    memberchk(TheDate, LogDays),
    % журнал не изменять
    !.
add_excl_day(TheDate-ExclType-_, LogDays, LogDays) :-
    % праздник из отпуска
    ExclType = "LEAVEDOCLINE",
    catch( wg_holiday(TheDate), _, fail ),
    % в журнал не заносить
    !.
add_excl_day(TheDate-ExclType-ExclWeekDay, LogDays, [TheDate|LogDays]) :-
    % детский день согласно дню недели
    ExclType = "KINDDAYLINE",
    weekday(TheDate, ExclWeekDay),
    % занести в журнал
    !.
add_excl_day(_-ExclType-_, LogDays, LogDays) :-
    % прочие даты из приказа о детском дне
    ExclType = "KINDDAYLINE",
    % пропускать
    !.
add_excl_day(TheDate-_-_, LogDays, [TheDate|LogDays]) :-
    % дату для прочих случаев занести в журнал
    !.

% исключаемые из первого месяца работы дни
% - для больничных
excl_first_month_days_sick(Scope, PK, Y, M, ExclDays) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % для первого движения по типу 1 (прием на работу)
    % где дата совпадает с проверяемым месяцем
    get_data(Scope, kb, usr_wg_MovementLine, [
        fEmplKey-EmplKey, fDocumentKey-FirstMoveKey, fFirstMoveKey-FirstMoveKey,
        fMoveYear-Y, fMoveMonth-M, fDateBegin-DateBegin, fMovementType-1 ]),
    % и является датой последнего приема на работу
    get_last_hire(Scope, PK, DateBegin),
    % исключить дни до принятия на работу
    atom_date(FirstMonthDate, date(Y, M, 1)),
    date_diff(FirstMonthDate, ExclDays, DateBegin),
    !.
excl_first_month_days_sick(_, _, _, _, 0) :-
    !.

% расчитать заработок за месяц
% - для начисления по-среднему
cacl_month_wage_avg(Scope, PK, Y, M, Wage) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % параметры выбора начислений
    member(ChargeOption, [tbl_charge, dbf_sums]),
    % взять начисления
    findall( Debit,
          % для начисления по одному из параметров
          % где дата совпадает с проверяемым месяцем
          ( usr_wg_TblCharge_mix(Scope, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fCalYear-Y, fCalMonth-M, fDateBegin-_,
                fDebit-Debit, fFeeTypeKey-FeeTypeKey ],
                                    ChargeOption),
          % и соответствующего типа
          once( ( var(FeeTypeKey)
                ; get_data(Scope, kb, usr_wg_FeeType, [
                            fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                            fFeeTypeKey-FeeTypeKey ])
                )
              )
          ),
    % в список начислений
    Debits ),
    % проверить список начислений
    \+ Debits = [],
    % всего за месяц
    sum_list(Debits, Wage),
    !.
cacl_month_wage_avg(_, _, _, _, 0.0) :-
    !.

% месяц работы полный
is_full_month(Scope, PK, Y-M) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % для первого движения по типу 1 (прием на работу)
    % где дата совпадает с проверяемым месяцем
    get_data(Scope, kb, usr_wg_MovementLine, [
        fEmplKey-EmplKey, fDocumentKey-FirstMoveKey, fFirstMoveKey-FirstMoveKey,
        fMoveYear-Y, fMoveMonth-M, fDateBegin-DateBegin, fMovementType-1 ]),
    % и является датой последнего приема на работу
    get_last_hire(Scope, PK, DateBegin),
    !,
    % параметры выбора графика
    member(NormOption, [tbl_cal_flex, tbl_day_norm]),
    % первый рабочий день по графику для проверяемого месяца
    once( usr_wg_TblDayNorm_mix(Scope, PK, Y-M, TheDay, _, 1, NormOption) ),
    !,
    % больше или равен дате первого движения
    TheDay @>= DateBegin,
    % то первый месяц работы полный
    !.
is_full_month(_, _, _) :-
    % проверяемый месяц не является первым месяцем работы
    !.

% в месяце есть отработанные дни или часы
is_month_worked(Scope, PK, Y-M) :-
    % если есть хотя бы один рабочий день
    usr_wg_TblCalLine_mix(Scope, PK, Y-M, _, DOW, HOW, _, _),
    % с контролем наличия дней или часов
    once( (DOW > 0 ; HOW > 0 ) ),
    % то в месяце есть отработанные дни или часы
    !.

% в месяце есть оплата
is_month_paid(Scope, PK, Y-M) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % если есть хотя бы одно начисление
    usr_wg_TblCharge_mix(Scope, [
        fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
        fCalYear-Y, fCalMonth-M, fDateBegin-_,
        fDebit-Debit, fFeeTypeKey-FeeTypeKey ],
                            _),
    % с контролем суммы
    Debit > 0,
    % соответствующего типа
    ( var(FeeTypeKey)
    ; once( get_data(Scope, kb, usr_wg_FeeType, [
                    fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                    fFeeTypeKey-FeeTypeKey ]) ) ),
    % то в месяце есть оплата
    !.

% взять расчетный месяц
get_month_incl(Scope, PK, Y, M, Variant) :-
    append(PK, [pMonthIncl-MonthInclList], Pairs),
    get_param_list(Scope, temp, Pairs),
    member(Y-M-Variant, MonthInclList).

% принять месяц для исчисления
take_month_incl(Scope, PK, Y, M, Variant) :-
    append(PK, [pMonthIncl-MonthInclList], Pairs),
    get_param_list(Scope, temp, Pairs),
    keysort([Y-M-Variant | MonthInclList], MonthInclList1),
    append(PK, [pMonthIncl-MonthInclList1], Pairs1),
    dispose_param_list(Scope, temp, Pairs),
    new_param_list(Scope, temp, Pairs1),
    !.
take_month_incl(Scope, PK, Y, M, Variant) :-
    append(PK, [pMonthIncl-[Y-M-Variant]], Pairs),
    new_param_list(Scope, temp, Pairs),
    !.

% проверка месяца по табелю
% - для отпусков
check_month_tab(_, _, []):-
    % больше месяцев для проверки нет
    !.
check_month_tab(Scope, PK, [Y-M|Periods]) :-
    % месяц работы полный
    is_full_month(Scope, PK, Y-M),
    % в месяце есть отработанные дни или часы
    is_month_worked(Scope, PK, Y-M),
    % в месяце есть оплата
    is_month_paid(Scope, PK, Y-M),
    % и выполняется одно из правил
    rule_month_tab(Scope, PK, Y-M, Variant),
    % то принять месяц для исчисления
    take_month_incl(Scope, PK, Y, M, Variant),
    !,
    % проверить остальные месяцы
    check_month_tab(Scope, PK, Periods).
check_month_tab(Scope, PK, [_|Periods]) :-
    !,
    % проверить остальные месяцы
    check_month_tab(Scope, PK, Periods).

% правила включения месяца в расчет
rule_month_tab(Scope, PK, Y-M, Rule) :-
    % по дням и часам за месяц
    Rule = by_days_houres,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % взять данные по графику и табелю за месяц
    get_month_norm_tab(Scope, PK, Y-M, NDays, TDays, NHoures, THoures),
    % если табель равен графику по дням и часам
    TDays =:= NDays, THoures =:= NHoures,
    % то месяц включается в расчет
    !.
rule_month_tab(Scope, PK, Y-M, Rule) :-
    % по часам за месяц
    Rule = by_houres,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % взять данные по графику и табелю за месяц
    get_month_norm_tab(Scope, PK, Y-M, _, _, NHoures, THoures),
    % если табель покрывает график по часам
    THoures >= NHoures,
    % то месяц включается в расчет
    !.
rule_month_tab(Scope, PK, Y-M, Rule) :-
    % по дням за месяц
    Rule = by_days,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % взять данные по графику и табелю за месяц
    get_month_norm_tab(Scope, PK, Y-M, NDays, TDays, _, _),
    % если табель покрывает график по дням
    TDays >= NDays,
    % то месяц включается в расчет
    !.

% взять данные по графику и табелю за месяц
get_month_norm_tab(Scope, PK, Y-M, NDays, TDays, NHoures, THoures) :-
    % взять из временных параметров дни и часы
    append(PK, [pYM-Y-M,
                pTDays-TDays, pTHoures-THoures,
                pNDays-NDays, pNHoures-NHoures],
                Pairs),
    get_param_list(Scope, temp, Pairs),
    !.
get_month_norm_tab(Scope, PK, Y-M, NDays, TDays, NHoures, THoures) :-
    % расчитать график и табель за месяц
    calc_month_norm_tab(Scope, PK, Y-M, NDays, TDays, NHoures, THoures),
    % записать во временные параметры дни и часы
    append(PK, [pYM-Y-M,
                pTDays-TDays, pTHoures-THoures,
                pNDays-NDays, pNHoures-NHoures],
                Pairs),
    new_param_list(Scope, temp, Pairs),
    !.

% расчитать график и табель за месяц
calc_month_norm_tab(Scope, PK, Y-M, NDays, TDays, NHoures, THoures) :-
    % расчитать график за месяц
    calc_month_norm(Scope, PK, Y-M, NormDays),
    % сумма дней и часов по графику
    sum_days_houres(NormDays, NDays, NHoures),
    % расчитать табель за месяц
    calc_month_tab(Scope, PK, Y-M, TabDays),
    % сумма дней и часов по табелю
    sum_days_houres(TabDays, TDays, THoures),
    !.

% расчитать график за месяц по одному из параметров
calc_month_norm(Scope, PK, Y-M, NormDays) :-
    % параметры выбора графика
    member(NormOption, [tbl_cal_flex, tbl_day_norm]),
    % взять дату/часы
    findall( TheDay-1-WDuration,
            % для рабочего дня
            ( usr_wg_TblDayNorm_mix(Scope, PK, Y-M, TheDay, WDuration, 1, NormOption),
            % с контролем наличия часов
            WDuration > 0 ),
    % в список дата/часы графика
    NormDays),
    % проверить список графика
    \+ NormDays = [],
    !.
calc_month_norm(_, _, _, []) :-
    !.

% расчитать график за год по одному из параметров
calc_year_norm(Scope, PK, NormDays) :-
    get_norm_periods(Scope, PK, Periods),
    calc_year_norm(Periods, Scope, PK, [], NormDays),
    !.
%
calc_year_norm([], _, _, NormDays, NormDays) :-
    !.
calc_year_norm([Y-M|Periods], Scope, PK, NormDays0, NormDays) :-
    calc_month_norm(Scope, PK, Y-M, NormDays1),
    append(NormDays0, NormDays1, NormDays2),
    !,
    calc_year_norm(Periods, Scope, PK, NormDays2, NormDays).

% нормативные периоды
get_norm_periods(Scope, PK, Periods) :-
    % взять нормативные даты ограничения расчета
    append(PK, [pDateNormFrom-DateFrom, pDateNormTo-DateTo], Pairs),
    get_param_list(Scope, run, Pairs),
    % сформировать список периодов
    make_periods(Scope, PK, DateFrom, DateTo, Periods),
    !.

% расчитать табель за месяц по одному из параметров
calc_month_tab(Scope, PK, Y-M, TabDays) :-
    % параметры выбора табеля
    member(TabelOption, [tbl_cal_flex, tbl_cal, tbl_charge, dbf_sums]),
    % взять данные из табеля
    findall( Date-DOW-HOW,
            % для проверяемого месяца
            ( usr_wg_TblCalLine_mix(Scope, PK, Y-M, Date, DOW, HOW, _, TabelOption),
            % с контролем наличия дней или часов
            once( (DOW > 0 ; HOW > 0 ) )
            ),
    % в список дата-день-часы
    TabDays),
    % проверить список табеля
    \+ TabDays = [],
    !.
calc_month_tab(_, _, _, []) :-
    !.
    
% сумма дней и часов
sum_days_houres(ListDays, Days, Houres) :-
    sum_days_houres(ListDays, Days, Houres, 0, 0),
    !.
%
sum_days_houres([], Days, Houres, Days, Houres).
sum_days_houres([_-DOW-HOW|ListDays], Days, Houres, Days0, Houres0) :-
    Days1 is Days0 + DOW,
    Houres1 is Houres0 + HOW,
    !,
    sum_days_houres(ListDays, Days, Houres, Days1, Houres1).

% проверка месяца по заработку
% - для отпусков
check_month_wage(_, _, []):-
    % больше месяцев для проверки нет
    !.
check_month_wage(Scope, PK, [Y-M|Periods]) :-
    % если месяц еще не включен в расчет
    \+ get_month_incl(Scope, PK, Y, M, _),
    % и выполняется одно из правил
    rule_month_wage(Scope, PK, Y-M, Variant),
    % то принять месяц для исчисления
    take_month_incl(Scope, PK, Y, M, Variant),
    !,
    % проверить следующий месяц
    check_month_wage(Scope, PK, Periods).
check_month_wage(Scope, PK, [_|Periods]) :-
    !,
    % проверить следующий месяц
    check_month_wage(Scope, PK, Periods).

% заработок за месяц в сравнении с полными месяцами
rule_month_wage(Scope, PK, Y-M, Rule) :-
    Shapes = [
              % покрывает любой из полных месяцев
              by_month_wage_any - wage_over_any,
              % покрывает каждый из полных месяцев
              by_month_wage_all - wage_over_list
              ],
    member(Rule - Condition, Shapes),
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % варианты правил полных месяцев
    wg_full_month_rules(FullMonthRules),
    % взять заработок и коэффициент осовременивания за проверяемый месяц
    get_month_wage(Scope, PK, Y, M, ModernCoef, Wage),
    % взять заработок
    findall( Wage1,
              % для расчетного месяца
            ( get_month_incl(Scope, PK, Y1, M1, Variant1),
              % который принят для исчисления по варианту полного месяца
              memberchk(Variant1, FullMonthRules),
              % с заработком и коэффициентом осовременивания за месяц
              get_month_wage(Scope, PK, Y1, M1, ModernCoef1, Wage1),
              % где коэффициенты для проверяемого и расчетного равны
              ModernCoef =:= ModernCoef1 ),
    % в список заработков
    Wages1 ),
    % если заработок проверяемого месяца соответствует условию
    Term =.. [Condition, Wage, Wages1], Term,
    % то месяц включается в расчет
    !.

% заработок покрывает любое значение из списка
wage_over_any(Over, [Head|_]) :-
    Over >= Head,
    !.
wage_over_any(Over, [_|Tail]) :-
    !,
    wage_over_any(Over, Tail).

% заработок покрывает все значения из списка
wage_over_list(Over, [Head|[]]) :-
    Over >= Head,
    !.
wage_over_list(Over, [Head|Tail]) :-
    Over >= Head,
    !,
    wage_over_list(Over, Tail).

% проверка месяца по типу начислений и типу часов
% - для отпусков
check_month_no_bad_type(_, _, []):-
    % больше месяцев для проверки нет
    !.
check_month_no_bad_type(Scope, PK, [Y-M|Periods]) :-
    % если месяц еще не включен в расчет
    \+ get_month_incl(Scope, PK, Y, M, _),
    % месяц работы полный
    is_full_month(Scope, PK, Y-M),
    % в месяце есть оплата
    is_month_paid(Scope, PK, Y-M),
    % и выполняется одно из правил
    rule_month_no_bad_type(Scope, PK, Y-M, Variant),
    % то принять месяц для исчисления
    take_month_incl(Scope, PK, Y, M, Variant),
    !,
    % проверить следующий месяц
    check_month_no_bad_type(Scope, PK, Periods).
check_month_no_bad_type(Scope, PK, [_|Periods]) :-
    !,
    % проверить следующий месяц
    check_month_no_bad_type(Scope, PK, Periods).

% отсутствие плохих типов начислений и часов
rule_month_no_bad_type(Scope, PK, Y-M, Rule) :-
    Rule = by_month_no_bad_type,
    % правило действительно
    is_valid_rule(Scope, PK, _, Rule),
    % если нет плохих типов начислений и часов
    \+ month_bad_type(Scope, PK, Y-M),
    % то месяц включается в расчет
    !.

% есть плохой тип часов
month_bad_type(Scope, PK, Y-M) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % если есть хотя бы один день по табелю
    usr_wg_TblCalLine_mix(Scope, PK, Y-M, _, _, _, HoureType, _),
    % с плохим типом часов
    nonvar(HoureType),
    HoureType > 0,
    once( get_data(Scope, kb, usr_wg_BadHourType, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey, fID-HoureType]) ),
    !.
% есть плохой тип начислений
month_bad_type(Scope, PK, Y-M) :-
    % разложить первичный ключ
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % если есть хотя бы одно начисление
    % где дата совпадает с проверяемым месяцем
    usr_wg_TblCharge_mix(Scope, [
        fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
        fCalYear-Y, fCalMonth-M, fDateBegin-_,
        fDebit-_, fFeeTypeKey-FeeTypeKey ],
                            _),
    % с плохим типом начисления
    nonvar(FeeTypeKey),
    FeeTypeKey > 0,
    once( get_data(Scope, kb, usr_wg_BadFeeType, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey, fID-FeeTypeKey]) ),
    !.

/* реализация - смешанные данные */

%% взять данные по начислению
% начисление из TblCharge
usr_wg_TblCharge_mix(Scope, ArgPairs, ChargeOption) :-
    ChargeOption = tbl_charge,
    get_data(Scope, kb, usr_wg_TblCharge, [fPayPeriod-PayPeriod|ArgPairs]),
    PayPeriod < 2.
% или начисление из dbf
% с согласованием спецификации по TblCharge
usr_wg_TblCharge_mix(Scope, ArgPairs, ChargeOption) :-
    ChargeOption = dbf_sums,
    % спецификация usr_wg_TblCharge
    ValuePairs = [
                fEmplKey-EmplKey, fFirstMoveKey-_,
                fCalYear-CalYear, fCalMonth-CalMonth, fDateBegin-DateBegin,
                fDebit-Debit, fFeeTypeKey-_
                ],
    member_list(ArgPairs, ValuePairs),
    % спецификация usr_wg_DbfSums
    DataPairs =  [
                fEmplKey-EmplKey,
                fInYear-CalYear, fInMonth-CalMonth, fDateBegin-DateBegin,
                fInSum-Debit
                ],
    get_data(Scope, kb, usr_wg_DbfSums, DataPairs).

%% взять данные по графику
% день месяца по календарному графику
usr_wg_TblDayNorm_mix(Scope, PK, Y-M, Date, Duration, WorkDay, NormOption) :-
    NormOption = tbl_cal_flex,
    get_Flex_by_type(Scope, PK, Y-M, Date, WorkDay, Duration, _, "plan").
% или день месяца по справочнику графика рабочего времени
usr_wg_TblDayNorm_mix(Scope, PK, Y-M, TheDay, WDuration, WorkDay, NormOption) :-
    NormOption = tbl_day_norm,
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    get_data(Scope, kb, usr_wg_TblCalDay, [
                fScheduleKey-ScheduleKey,
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fWYear-Y, fWMonth-M, fTheDay-TheDay,
                fWDuration-WDuration, fWorkDay-WorkDay ]),
    check_schedule(Scope, PK, TheDay, ScheduleKey).

%
check_schedule(Scope, PK, TheDay, ScheduleKey) :-
    append(PK,
            [pDateFrom-DateFrom, pDateTo-DateTo, pScheduleKey-ScheduleKey],
                Pairs),
    get_param_list(Scope, temp, Pairs),
    TheDay @>= DateFrom, TheDay @< DateTo,
    !.
check_schedule(Scope, PK, _, ScheduleKey) :-
    get_last_schedule(Scope, PK, ScheduleKey),
    !.

%% взять данные по табелю
% день месяца по табелю мастера
usr_wg_TblCalLine_mix(Scope, PK, Y-M, Date, Days, Duration, HoureType, TabelOption) :-
    TabelOption = tbl_cal_flex,
    get_Flex_by_type(Scope, PK, Y-M, Date, Days, Duration, HoureType, "fact").
% или день месяца по табелю
usr_wg_TblCalLine_mix(Scope, PK, Y-M, Date, Days, Duration, HoureType, TabelOption) :-
    TabelOption = tbl_cal,
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    get_data(Scope, kb, usr_wg_TblCalLine, [
                fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fCalYear-Y, fCalMonth-M, fDate-Date,
                fDuration-Duration, fHoureType-HoureType]),
    once( (Duration > 0, Days = 1 ; Days = 0) ).
% или табель дни-часы из начислений
usr_wg_TblCalLine_mix(Scope, PK, Y-M, Date, DOW, HOW, 0, TabelOption) :-
    TabelOption = tbl_charge,
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    ArgPairs = [fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                fCalYear-Y, fCalMonth-M, fDateBegin-Date,
                fFeeTypeKey-FeeTypeKey, fDOW-DOW, fHOW-HOW],
    get_data(Scope, kb, usr_wg_TblCharge, [fPayPeriod-_|ArgPairs]),
    once( get_data(Scope, kb, usr_wg_FeeType, [
                    fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey,
                    fFeeTypeKey-FeeTypeKey, fAvgDayHOW-1]) ).
% или день месяца из dbf
usr_wg_TblCalLine_mix(Scope, PK, Y-M, Date, 0, InHoures, 0, TabelOption) :-
    TabelOption = dbf_sums,
    PK = [pEmplKey-EmplKey, pFirstMoveKey-_],
    get_data(Scope, kb, usr_wg_DbfSums, [
                fEmplKey-EmplKey, fInHoures-InHoures,
                fInYear-Y, fInMonth-M, fDateBegin-Date]).

% день месяца по календарному графику или табелю мастера
% FlexType: "plan" ; "fact"
get_Flex_by_type(Scope, PK, Y-M, Date, Days, Duration, HoureType, FlexType) :-
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    gd_pl_ds(Scope, kb, usr_wg_TblCal_FlexLine, 68, _),
    make_list(62, TeilArgs),
    Term =..[ usr_wg_TblCal_FlexLine, FlexType, EmplKey, FirstMoveKey, Y, M, _ | TeilArgs ],
    catch( call( Term ), _, fail),
    member(D, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
                17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]),
    atom_date(Date, date(Y, M, D)),
    S is (D - 1) * 2 + 6 + 1,
    H is S + 1,
    arg(S, Term, Duration0),
    once( ( number(Duration0), Duration = Duration0
            ; atom_number(Duration0, Duration)
            ; Duration = 0 ) ),
    arg(H, Term, HoureType0),
    once( ( number(HoureType0), HoureType = HoureType0
            ; atom_number(HoureType0, HoureType)
            ; HoureType = 0 ) ),
    once( (Duration > 0, Days = 1 ; Days = 0) ).


/* реализация - механизм подготовки данных */
    
%% engine_loop(+Scope, +Type, +PK)
%

% args handler
engine_loop(Scope, Type, PK) :-
    \+ ground([Scope, Type, PK]),
    !,
    fail.
% fail handler
engine_loop(Scope, _, PK) :-
    engine_fail_step(Type),
    get_param_list(Scope, Type, PK),
    !,
    fail.
% deal handler
engine_loop(Scope, Type, PK) :-
    engine_deal_step(Type),
    !,
    get_param_list(Scope, Type, PK),
    !.
% data handler
engine_loop(Scope, Type, PK) :-
    engine_data_step(Type, TypeNextStep),
    get_param_list(Scope, Type, PK),
    \+ get_param_list(Scope, TypeNextStep, PK),
    prepare_data(Scope, Type, PK, TypeNextStep),
    !,
    engine_loop(Scope, TypeNextStep, PK).
engine_loop(Scope, Type, PK) :-
    engine_data_step(Type, TypeNextStep),
    !,
    engine_loop(Scope, TypeNextStep, PK).
% restart handler
engine_loop(Scope, Type, PK) :-
    engine_restart_step(Type, TypeNextStep),
    forall( ( get_param_list(Scope, ParamType, PK, Pairs),
              \+ ParamType = TypeNextStep ),
            dispose_param_list(Scope, ParamType, Pairs)
          ),
    !,
    engine_loop(Scope, TypeNextStep, PK).
% error handler
engine_loop(Scope, Type, PK) :-
    engine_error_step(TypeNextStep),
    \+ get_param_list(Scope, TypeNextStep, PK),
    get_local_date_time(DT),
    append(PK, [Type, DT], PairsNextStep),
    new_param_list(Scope, TypeNextStep, PairsNextStep),
    !,
    fail.

%
engine_data_step(in, run).
engine_data_step(run, query).
engine_data_step(query, data).
%
engine_deal_step(run) :-
    debug_mode,
    !.
engine_deal_step(data).
%
engine_fail_step(out).
engine_fail_step(error).
%
engine_restart_step(restart, in).
%
engine_error_step(error).

 %
%%

/* реализация - подготовка данных */

% in-run
prepare_data(Scope, Type, PK, TypeNextStep) :-
    memberchk(Scope, [wg_avg_wage_vacation, wg_avg_wage_sick, wg_avg_wage_avg]),
    Type = in, TypeNextStep = run,
    % MonthQty, MonthBonusQty, Pairs01, Pairs02
    ( get_param_list(Scope, Type, [pCommon-1], Pairs01) ; Pairs01 = [] ),
    get_param_list(Scope, Type, [pMonthQty-MonthQty], Pairs02),
    ( member_list([pMonthBonusQty-MonthBonusQty], Pairs02) ; MonthBonusQty = 0 ),
    % DateCalc, MonthOffset, MonthBefore, Pairs
    append(PK, [pDateCalc-DateCalc], Pairs03),
    get_param_list(Scope, Type, Pairs03, Pairs),
    ( member_list([pMonthOffset-MonthOffset], Pairs) ; MonthOffset = 0 ),
    ( member_list([pMonthBefore-MonthBefore], Pairs) ; MonthBefore = 0 ),
    % DateCalcFrom, DateCalcTo
    atom_date(DateCalc, date(Y0, M0, _)),
    atom_date(DateCalcTo0, date(Y0, M0, 1)),
    MonthOffset1 is (- MonthOffset),
    date_add(DateCalcTo0, MonthOffset1, month, DateCalcTo),
    MonthAdd is (- (MonthQty + MonthBefore)),
    date_add(DateCalcTo, MonthAdd, month, DateCalcFrom),
    % DateNormFrom, DateNormTo
    date_add(DateCalcTo, -1, day, DateCalcTo1),
    atom_date(DateCalcTo1, date(Y, _, _)),
    atom_date(DateNormFrom, date(Y, 1, 1)),
    Y1 is Y + 1,
    atom_date(DateNormTo, date(Y1, 1, 1)),
    % DateBonusFrom
    MonthBonusQty1 is (- MonthBonusQty),
    date_add(DateCalcFrom, MonthBonusQty1, month, DateBonusFrom),
    % PairsNextStep
    append([Pairs,
                [
                pDateCalcFrom-DateCalcFrom, pDateCalcTo-DateCalcTo,
                pDateNormFrom-DateNormFrom, pDateNormTo-DateNormTo,
                pDateBonusFrom-DateBonusFrom, pDateBonusTo-DateCalcFrom
                ],
            Pairs01, Pairs02
            ],
            PairsNextStep),
    new_param_list(Scope, TypeNextStep, PairsNextStep),
    !.

% run-query
prepare_data(Scope, Type, PK, TypeNextStep) :-
    memberchk(Scope, [wg_avg_wage_vacation, wg_avg_wage_sick, wg_avg_wage_avg]),
    Type = run, TypeNextStep = query,
    get_param_list(Scope, Type, PK, Pairs),
    forall( ( gd_pl_ds(Scope, kb, PredicateName, Arity, _),
              Query = PredicateName/Arity,
              is_valid_sql(Query),
              get_sql(Scope, kb, Query, SQL, Params),
              member_list(Params, Pairs),
              prepare_sql(SQL, Params, PrepSQL),
              append(PK, [pQuery-Query, pSQL-PrepSQL], PairsNextStep),
              \+ get_param_list(Scope, TypeNextStep, PairsNextStep)
            ),
            new_param_list(Scope, TypeNextStep, PairsNextStep)
          ),
    !.

/* реализация - расширение для клиента */

%  05. Начисление отпусков

% загрузка входных данных по сотруднику
% CoefOption: fc_fcratesum ; ml_rate ; ml_msalary
avg_wage_in(EmplKey, FirstMoveKey, DateCalc, MonthOffset, CoefOption) :-
    Scope = wg_avg_wage_vacation, Type = in,
    new_param_list(Scope, Type,
        [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey,
         pDateCalc-DateCalc, pMonthOffset-MonthOffset,
         pCoefOption-CoefOption]),
    !.

% выгрузка детальных выходных данных по сотруднику
avg_wage_det(EmplKey, FirstMoveKey,
                Period, Rule, Wage, ModernCoef, ModernWage,
                TabDays, NormDays, TabHoures, NormHoures,
                SalaryOld, SalaryNew) :-
    % параметры контекста
    Scope = wg_avg_wage_vacation, Type = temp,
    % шаблон первичного ключа
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % для каждого периода
    % взять данные по табелю и графику
    append(PK, [pYM-Y-M,
                    pTDays-TabDays, pTHoures-TabHoures,
                    pNDays-NormDays, pNHoures-NormHoures],
            Pairs),
    get_param_list(Scope, Type, Pairs),
    once( (
        % если для первого движения по типу 1 (прием на работу)
        % где дата совпадает с проверяемым месяцем
        get_data(Scope, kb, usr_wg_MovementLine, [
            fEmplKey-EmplKey,
            fDocumentKey-FirstMoveKey, fFirstMoveKey-FirstMoveKey,
            fMoveYear-Y, fMoveMonth-M, fDateBegin-Period, fMovementType-1 ]),
        % и является датой последнего приема на работу
        get_last_hire(Scope, PK, Period)
        % то период есть дата начала работы
        ;
        % иначе сформировать дату периода, как первый день месяца
        atom_date(Period, date(Y, M, 1))
        ) ),
    % взять данные по правилам расчета
    append(PK, [pMonthIncl-MonthIncl], Pairs1),
    once( ( get_param_list(Scope, Type, Pairs1) ; MonthIncl = [] ) ),
    once( ( memberchk(Y-M-Rule, MonthIncl) ; Rule = none ) ),
    % взять данные по заработку
    once( ( ( append(PK, [pYM-Y-M,
                            pWage-Wage, pModernCoef-ModernCoef, pModernWage-ModernWage,
                            pSalaryOld-SalaryOld, pSalaryNew-SalaryNew],
                        Pairs2),
              get_param_list(Scope, Type, Pairs2) )
              ; [Wage, ModernCoef, ModernWage, SalaryOld, SalaryNew] = [0, 1, 0, 0, 0] ) ),
    %
    % есть отработанные часы или заработок
    once( ( TabHoures > 0 ; ModernWage > 0 ) ),
    true.

%  06. Начисление больничных

% загрузка входных данных по сотруднику
avg_wage_sick_in(EmplKey, FirstMoveKey, DateCalc, IsAvgWageDoc) :-
    Scope = wg_avg_wage_sick, Type = in,
    new_param_list(Scope, Type,
        [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey,
         pDateCalc-DateCalc, pIsAvgWageDoc-IsAvgWageDoc]),
    !.

% выгрузка детальных выходных данных по сотруднику
avg_wage_sick_det(EmplKey, FirstMoveKey,
                    Period, Rule,
                    MonthDays, ExclDays, CalcDays, IsFullMonth, IsSpecMonth,
                    Wage,
                    TabDays, NormDays, TabHoures, NormHoures) :-
    % параметры контекста
    Scope = wg_avg_wage_sick, Type = temp,
    % шаблон первичного ключа
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % для каждого периода
    % взять данные по расчетным дням
    append(PK, [pYM-Y-M, pRule-Rule,
                pMonthDays-MonthDays, pExclDays-ExclDays,
                pCalcDays-CalcDays, pIsFullMonth-IsFullMonth,
                pIsSpecMonth-IsSpecMonth],
            Pairs),
    get_param_list(Scope, temp, Pairs),
    % взять данные по заработку
    append(PK, [pYM-Y-M, pWage-Wage], Pairs1),
    get_param_list(Scope, Type, Pairs1),
    % взять данные по табелю и графику
    append(PK, [pYM-Y-M,
                    pTDays-TabDays, pTHoures-TabHoures,
                    pNDays-NormDays, pNHoures-NormHoures],
            Pairs2),
    get_param_list(Scope, Type, Pairs2),
    once( (
        % если для первого движения по типу 1 (прием на работу)
        % где дата совпадает с проверяемым месяцем
        get_data(Scope, kb, usr_wg_MovementLine, [
            fEmplKey-EmplKey,
            fDocumentKey-FirstMoveKey, fFirstMoveKey-FirstMoveKey,
            fMoveYear-Y, fMoveMonth-M, fDateBegin-Period, fMovementType-1 ]),
        % и является датой последнего приема на работу
        get_last_hire(Scope, PK, Period)
        % то период есть дата начала работы
        ;
        % иначе сформировать дату периода, как первый день месяца
        atom_date(Period, date(Y, M, 1))
        ) ),
    true.

%  12. Начисление по-среднему

% загрузка входных данных по сотруднику
avg_wage_avg_in(EmplKey, FirstMoveKey, DateCalc, CalcByHoure, MonthBefore) :-
    Scope = wg_avg_wage_avg, Type = in,
    new_param_list(Scope, Type,
        [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey,
         pDateCalc-DateCalc, pCalcByHoure-CalcByHoure,
         pMonthBefore-MonthBefore]),
    !.
    
% выгрузка детальных выходных данных по сотруднику
avg_wage_avg_det(EmplKey, FirstMoveKey,
                    Period, Wage,
                    TabDays, NormDays, TabHoures, NormHoures) :-
    % параметры контекста
    Scope = wg_avg_wage_avg, Type = temp,
    % шаблон первичного ключа
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % для каждого периода
    % взять данные по заработку
    append(PK, [pYM-Y-M, pWage-Wage], Pairs1),
    get_param_list(Scope, Type, Pairs1),
    % взять данные по табелю и графику
    append(PK, [pYM-Y-M,
                    pTDays-TabDays, pTHoures-TabHoures,
                    pNDays-NormDays, pNHoures-NormHoures],
            Pairs2),
    get_param_list(Scope, Type, Pairs2),
    once( (
        % если для первого движения по типу 1 (прием на работу)
        % где дата совпадает с проверяемым месяцем
        get_data(Scope, kb, usr_wg_MovementLine, [
            fEmplKey-EmplKey,
            fDocumentKey-FirstMoveKey, fFirstMoveKey-FirstMoveKey,
            fMoveYear-Y, fMoveMonth-M, fDateBegin-Period, fMovementType-1 ]),
        % и является датой последнего приема на работу
        get_last_hire(Scope, PK, Period)
        % то период есть дата начала работы
        ;
        % иначе сформировать дату периода, как первый день месяца
        atom_date(Period, date(Y, M, 1))
        ) ),
    true.


%  05, 06, 12

% выгрузка SQL-запросов по сотруднику
avg_wage_sql(Scope, EmplKey, FirstMoveKey, PredicateName, Arity, SQL) :-
    Type = query, TypeNextStep = data,
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    Query = PredicateName/Arity,
    append(PK, [pQuery-Query, pSQL-SQL], Pairs),
    get_param_list(Scope, Type, Pairs),
    \+ get_param_list(Scope, TypeNextStep, Pairs).

% подтвеждение формирования фактов по сотруднику
avg_wage_kb(Scope, EmplKey, FirstMoveKey, PredicateName, Arity, SQL) :-
    Type = query, TypeNextStep = data,
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    Query = PredicateName/Arity,
    append(PK, [pQuery-Query, pSQL-SQL], Pairs),
    get_param_list(Scope, Type, Pairs),
    \+ get_param_list(Scope, TypeNextStep, Pairs),
    new_param_list(Scope, TypeNextStep, Pairs),
    !.

% выгрузка данных выполнения по сотруднику
avg_wage_run(Scope, EmplKey, FirstMoveKey, DateCalcFrom, DateCalcTo) :-
    Type = run,
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    append(PK, [pDateCalcFrom-DateCalcFrom, pDateCalcTo-DateCalcTo], Pairs),
    get_param_list(Scope, Type, Pairs).

% выгрузка выходных данных по сотруднику
avg_wage_out(Scope, EmplKey, FirstMoveKey, AvgWage, Variant) :-
    Type = out,
    % шаблон первичного ключа
    PK = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey],
    % взять данные по результатам расчета
    append(PK, [pAvgWage-AvgWage, pVariant-Variant], Pairs),
    get_param_list(Scope, Type, Pairs).

% удаление данных по сотруднику
avg_wage_clean(Scope, EmplKey, FirstMoveKey) :-
    gd_pl_ds(Scope, Type, Name, _, _),
    del_data(Scope, Type, Name, [fEmplKey-EmplKey, fFirstMoveKey-FirstMoveKey]),
    fail.
avg_wage_clean(Scope, EmplKey, FirstMoveKey) :-
    get_param_list(Scope, Type, [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey], Pairs),
    dispose_param_list(Scope, Type, Pairs),
    fail.
avg_wage_clean(_, _, _) :-
    !.

/**/

% section twg_struct
% расчет структуры
% - для отпусков
% - для больничных
%

/* реализация */

%
struct_vacation_sql(DocKey, DateBegin, DateEnd, PredicateName, Arity, SQL) :-
    Scope = wg_struct_vacation, NextType = run,
    Pairs = [pDocKey-DocKey, pDateBegin-DateBegin, pDateEnd-DateEnd],
    get_sql(Scope, kb, Query, SQL0, Params),
    is_valid_sql(Query),
    Query = PredicateName/Arity,
    member_list(Params, Pairs),
    prepare_sql(SQL0, Params, SQL),
    Pairs1 = [pDocKey-DocKey, pQuery-Query, pSQL-SQL],
    new_param_list(Scope, NextType, Pairs1).

%
struct_vacation_in(DateCalc, _, _, AvgWage, _) :-
    wg_vacation_compensation(DateFrom, Duration, 1),
    atom_date(DateCalc, date(Year, Month, _)),
    month_days(Year, Month, Days),
    atom_date(AccDate, date(Year, Month, Days)),
    atom_date(DateFrom, date(Y, M, _)),
    atom_date(IncludeDate, date(Y, M, 1)),
    Summa is Duration * AvgWage,
    OutPairs = [
                pAccDate-AccDate, pIncludeDate-IncludeDate,
                pDuration-Duration, pSumma-Summa,
                pDateBegin-AccDate, pDateEnd-AccDate,
                pVcType-0
                ],
    new_param_list(struct_vacation, out, OutPairs),
    !.
struct_vacation_in(DateCalc, DateBegin, DateEnd, AvgWage, SliceOption) :-
    atom_date(DateCalc, date(Year, Month, _)),
    month_days(Year, Month, Days),
    atom_date(AccDate, date(Year, Month, Days)),
    once( (SliceOption = 0, FilterVcType = 0 ; true) ),
    findall( VcType-Slice,
                ( wg_vacation_slice(VcType, Slice), VcType = FilterVcType ),
             SliceList0 ),
    keysort(SliceList0, [Slice0|SliceList1]),
    append(SliceList1, [Slice0], SliceList),
    struct_vacation_calc(SliceList, _-0, AccDate, DateBegin, DateEnd, AvgWage),
    !.

%
struct_vacation_calc([Slice|SliceList], _-Slice0, AccDate, DateBegin, DateEnd, AvgWage) :-
    Slice0 =:= 0,
    !,
    struct_vacation_calc(SliceList, Slice, AccDate, DateBegin, DateEnd, AvgWage).
struct_vacation_calc(_, _, _, '', '', _) :-
    !.
struct_vacation_calc([], _-Slice, _, _, _, _) :-
    Slice =:= 0,
    !.
struct_vacation_calc(SliceList, VcType-Slice, AccDate, DateBegin, DateEnd, AvgWage) :-
    make_period(DateBegin, DateEnd, DateBegin1, DateEnd1, DateBegin2, DateEnd2, Slice, Slice2),
    atom_date(DateBegin1, date(Y, M, _)),
    atom_date(IncludeDate, date(Y, M, 1)),
    sum_vacation_days(DateBegin1, DateEnd1, 1, Duration),
    Summa is Duration * AvgWage,
    OutPairs = [
                pAccDate-AccDate, pIncludeDate-IncludeDate,
                pDuration-Duration, pSumma-Summa,
                pDateBegin-DateBegin1, pDateEnd-DateEnd1,
                pVcType-VcType
                ],
    new_param_list(struct_vacation, out, OutPairs),
    !,
    struct_vacation_calc(SliceList, VcType-Slice2, AccDate, DateBegin2, DateEnd2, AvgWage).

%
sum_vacation_days(DateBegin, DateBegin, Duration0, Duration1) :-
    ( catch( wg_holiday(DateBegin), _, fail ), Duration1 is Duration0 - 1
    ; Duration1 = Duration0 ),
    !.
sum_vacation_days(DateBegin, DateEnd, Duration0, Duration) :-
    date_add(DateBegin, 1, day, DateBegin1),
    ( catch( wg_holiday(DateBegin), _, fail ), Duration1 = Duration0
    ; Duration1 is Duration0 + 1 ),
    !,
    sum_vacation_days(DateBegin1, DateEnd, Duration1, Duration).

%
struct_sick_sql(EmplKey, FirstMoveKey, DateBegin, DateEnd, PredicateName, Arity, SQL) :-
    Scope = wg_struct_sick, Type = in, NextType = run,
    % формирование параметров выполнения
    DateCalcFrom = DateBegin,
    date_add(DateEnd, 1, day, DateCalcTo),
    once( ( get_param_list(Scope, Type, [pCommon-1], Pairs01) ; Pairs01 = [] ) ),
    get_param_list(Scope, Type, [pBudgetPart-_], Pairs02),
    append(Pairs01, Pairs02, Pairs0),
    append(Pairs0,
                [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey,
                 pDateCalcFrom-DateCalcFrom, pDateCalcTo-DateCalcTo,
                 pDateNormFrom-DateCalcFrom, pDateNormTo-DateCalcTo],
            Pairs),
    new_param_list(Scope, NextType, Pairs),
    % формирование SQL-запроса
    get_sql(Scope, kb, Query, SQL0, Params),
    is_valid_sql(Query),
    Query = PredicateName/Arity,
    member_list(Params, Pairs),
    prepare_sql(SQL0, Params, SQL),
    % добавление SQL-запроса к параметрам выполнения
    Pairs1 = [pEmplKey-EmplKey, pFirstMoveKey-FirstMoveKey,
              pQuery-Query, pSQL-SQL],
    new_param_list(Scope, NextType, Pairs1).

%
struct_sick_in(DateCalc, DateBegin, DateEnd, AvgWage, CalcType, BudgetOption, IsPregnancy, IllType) :-
    Scope = wg_struct_sick, Type = in, NextType = run,
    % шаблон первичного ключа
    PK = [pEmplKey-_, pFirstMoveKey-_],
    % формирование временных данных по графику работы
    get_param_list(Scope, NextType, PK),
    make_schedule(Scope, PK),
    % формирование временных данных параметров расчета
    Pairs0 = [pBudgetOption-BudgetOption, pIsPregnancy-IsPregnancy, pIllType-IllType],
    append(PK, Pairs0, Pairs),
    new_param_list(Scope, temp, Pairs),
    %
    atom_date(DateCalc, date(Year, Month, _)),
    month_days(Year, Month, Days),
    atom_date(AccDate, date(Year, Month, Days)),
    date_diff(DateBegin, Duration0, DateEnd),
    Duration is Duration0 + 1,
    %
    sick_slice_list(Scope, Type, CalcType, Duration, SliceList0),
    %
    date_diff(DateCalc, DurationBefore, DateBegin),
    sick_slice_list_excl(SliceList0, SliceList, DurationBefore),
    %
    struct_sick_calc(SliceList, _-0, AccDate, DateBegin, DateEnd, AvgWage, Scope, PK),
    !.

%
sick_slice_list(Scope, Type, CalcType, Duration, SliceList) :-
    Params = [
              pFirstCalcType-FirstCalcType,
              pFirstDuration-FirstDuration,
              pFirstPart-FirstPart
             ],
    get_param_list(Scope, Type, Params),
    sick_slice_list(Scope, Type, [1.0-Duration], CalcType, FirstCalcType, FirstPart-FirstDuration, SliceList),
    !.
%
sick_slice_list(_, _, SliceList0, CalcType, CalcType, FirstSlice, [FirstSlice|SliceList0]) :-
    !.
sick_slice_list(Scope, Type, [_-Duration], CalcType, _, FirstPart-FirstDuration, SliceList) :-
    Params = [
              pCutCalcType-CalcType,
              pCutDuration-CutDuration,
              pCutPart-CutPart
             ],
    get_param_list(Scope, Type, Params),
    Part2 is FirstPart * CutPart,
    Duration2 is FirstDuration - CutDuration,
    append([[0.0-CutDuration], [Part2-Duration2], [CutPart-Duration]], SliceList),
    !.
sick_slice_list(_, _, SliceList, _, _, _, SliceList) :-
    !.

%
sick_slice_list_excl(SliceList, SliceList, 0) :-
    !.
sick_slice_list_excl([LastSlice|[]], [LastSlice], _) :-
    !.
sick_slice_list_excl([Slice|SliceList], [Slice1|SliceList1], DurationBefore) :-
    sick_slice_excl(Slice, Slice1, DurationBefore, DurationBefore1),
    !,
    sick_slice_list_excl(SliceList, SliceList1, DurationBefore1).

%
sick_slice_excl(Part-Duration, Part-Duration1, DurationBefore, DurationBefore1) :-
    Duration0 is Duration - DurationBefore,
    ( Duration0 > 0 -> Duration1 = Duration0 ; Duration1 = 0),
    DurationBefore0 is DurationBefore - Duration,
    ( DurationBefore0 > 0 -> DurationBefore1 = DurationBefore0 ; DurationBefore1 = 0),
    !.

%
struct_sick_calc([Slice|SliceList], _-Slice0, AccDate, DateBegin, DateEnd, AvgWage, Scope, PK) :-
    Slice0 =:= 0,
    !,
    struct_sick_calc(SliceList, Slice, AccDate, DateBegin, DateEnd, AvgWage, Scope, PK).
struct_sick_calc(_, _, _, '', '', _, _, _) :-
    !.
struct_sick_calc([], _-Slice, _, _, _, _, _, _) :-
    Slice =:= 0,
    !.
struct_sick_calc(SliceList, SickPart0-Slice, AccDate, DateBegin, DateEnd, AvgWage0, Scope, PK) :-
    make_period(DateBegin, DateEnd, DateBegin1, DateEnd1, DateBegin2, DateEnd2, Slice, Slice2),
    atom_date(DateBegin1, date(Y, M, _)),
    atom_date(IncludeDate, date(Y, M, 1)),
    Scope = wg_struct_sick,
    % взять временные данные параметров расчета
    Pairs0 = [pBudgetOption-BudgetOption, pIsPregnancy-IsPregnancy, pIllType-IllType],
    append(PK, Pairs0, Pairs),
    get_param_list(Scope, temp, Pairs),
    %
    ( BudgetOption = 1,
      ( SickPart0 =:= 0, SickPart = 0.0
      ; SickPart = 1.0
      )
    ; SickPart = SickPart0
    ),
    Percent is SickPart * 100,
    date_add(DateEnd1, 1, day, DateEnd11),
    sum_sick_days(DateBegin1, DateEnd11, 0, DOI, 0, HOI, IllType, Scope, PK),
    ( BudgetOption = 1,
      get_avg_wage_budget(Scope, in, Y-M, AvgWage)
    ; check_avg_wage(Scope, IsPregnancy, Y-M, AvgWage0, AvgWage)
    ),
    Summa is round(DOI * AvgWage * SickPart),
    OutPairs = [
                pAccDate-AccDate, pIncludeDate-IncludeDate,
                pPercent-Percent, pDOI-DOI, pHOI-HOI, pSumma-Summa,
                pDateBegin-DateBegin1, pDateEnd-DateEnd1
                ],
    new_param_list(Scope, out, OutPairs),
    !,
    struct_sick_calc(SliceList, SickPart-Slice2, AccDate, DateBegin2, DateEnd2, AvgWage0, Scope, PK).

%
check_avg_wage(_, 1, _, AvgWage, AvgWage) :-
    % есть признак Декретный
    !.
check_avg_wage(Scope, _, Y-M, AvgWage0, AvgWage) :-
    % среднедневная зп для месяца по среднемесячной зп
    avg_wage_by_avg_salary(Scope, Y-M, AvgWage1),
    % определить среднедневную зп
    ( AvgWage0 =< AvgWage1, AvgWage = AvgWage0
    ; AvgWage = AvgWage1 ),
    !.
check_avg_wage(_, _, _, AvgWage, AvgWage) :-
    !.
%
make_period(DateBegin, DateEnd, DateBegin, DateEnd1, DateBegin2, DateEnd2, Slice, Slice2) :-
    head_period(DateBegin, DateEnd, DateEnd1, Slice, Slice2),
    teil_period(DateEnd, DateEnd1, DateBegin2, DateEnd2),
    !.

%
head_period(DateBegin, DateEnd, DateBegin, Slice, Slice2) :-
   date_add(DateBegin, 1, day, DateBegin1),
   atom_date(DateBegin, date(Y, M, _)),
   ( \+ atom_date(DateBegin1, date(Y, M, _)), next_slice(DateBegin, Slice, Slice2)
   ; DateBegin1 @> DateEnd, Slice2 = 0
   ; Slice =:= 1, next_slice(DateBegin, Slice, Slice2)
   ),
   !.
head_period(DateBegin, DateEnd, DateEnd1, Slice0, Slice2) :-
   date_add(DateBegin, 1, day, DateBegin1),
   next_slice(DateBegin, Slice0, Slice1),
   !,
   head_period(DateBegin1, DateEnd, DateEnd1, Slice1, Slice2).

%
next_slice(DateBegin, Slice, Slice) :-
   catch( wg_holiday(DateBegin), _, fail ),
   !.
next_slice(_, Slice, Slice2) :-
   Slice2 is Slice - 1,
   !.

%
teil_period(DateEnd, DateEnd, '', '') :-
    !.
teil_period(DateEnd, DateEnd1, DateBegin2, DateEnd) :-
    date_add(DateEnd1, 1, day, DateBegin2),
    !.

%
sum_sick_days(DateBegin, DateBegin, DOI, DOI, HOI, HOI, _, _, _) :-
    !.
sum_sick_days(DateBegin, DateEnd, DOI0, DOI, HOI0, HOI, IllType, Scope, PK) :-
    add_sick_norm(DateBegin, DOI0, HOI0, DOI1, HOI1, IllType, Scope, PK),
    date_add(DateBegin, 1, day, DateBegin1),
    !,
    sum_sick_days(DateBegin1, DateEnd, DOI1, DOI, HOI1, HOI, IllType, Scope, PK).

%
add_sick_norm(TheDay, DOI0, HOI0, DOI1, HOI1, IllType, Scope, PK) :-
    ( member(NormOption, [tbl_cal_flex, tbl_day_norm]),
      usr_wg_TblDayNorm_mix(Scope, PK, _, TheDay, WDuration, 1, NormOption),
      WDuration > 0,
      DOI1 is DOI0 + 1, HOI1 is HOI0 + WDuration
    ;
      ( catch( wg_job_ill_type(IllType), _, fail),
        DOI1 = DOI0
      ; DOI1 is DOI0 + 1
      ), HOI1 = HOI0
    ),
    !.

%
struct_vacation_out(AccDate, IncludeDate, Duration, Summa, DateBegin, DateEnd, VcType) :-
    OutPairs = [
                pAccDate-AccDate, pIncludeDate-IncludeDate,
                pDuration-Duration, pSumma-Summa,
                pDateBegin-DateBegin, pDateEnd-DateEnd,
                pVcType-VcType
                ],
    get_param_list(struct_vacation, out, OutPairs).

%
struct_sick_out(AccDate, IncludeDate, Percent, DOI, HOI, Summa, DateBegin, DateEnd) :-
    Scope = wg_struct_sick,
    OutPairs = [
                pAccDate-AccDate, pIncludeDate-IncludeDate,
                pPercent-Percent, pDOI-DOI, pHOI-HOI, pSumma-Summa,
                pDateBegin-DateBegin, pDateEnd-DateEnd
                ],
    get_param_list(Scope, out, OutPairs).

% взять среднедневной БПМ на текущий месяц
get_avg_wage_budget(Scope, Type, Y-M, AvgWageBudget) :-
    % первая дата месяца
    atom_date(FirstMonthDate, date(Y, M, 1)),
    % взять БПМ
    findall( Budget0,
                  % взять данные по БПМ
                ( get_data(Scope, kb, gd_const_budget, [
                            fConstDate-ConstDate, fBudget-Budget0]),
                  % где дата константы меньше первой даты месяца
                  ConstDate @=< FirstMonthDate
                ),
    % в список БПМ
    BudgetList),
    % проверить список БПМ
    \+ BudgetList = [],
    % последние данные по БПМ за месяц
    last(BudgetList, MonthBudget),
    % календарных дней в месяце
    month_days(Y, M, MonthDays),
    % коэфициент для расчета по БПМ
    get_param(Scope, Type, pBudgetPart-BudgetPart),
    % среднедневной БПМ
    AvgWageBudget is MonthBudget * BudgetPart / MonthDays,
    !.
get_avg_wage_budget(_, _, _, 0) :-
    !.

% среднедневная зп для месяца по среднемесячной зп
avg_wage_by_avg_salary(Scope, Y-M, MonthAvgWage) :-
    % первая дата месяца
    atom_date(FirstMonthDate, date(Y, M, 1)),
    % взять среднюю зп
    findall( AvgSalary0,
                  % взять данные по средней зп
                ( get_data(Scope, kb, gd_const_AvgSalaryRB, [
                            fConstDate-ConstDate, fAvgSalaryRB-AvgSalary0]),
                  % где дата константы меньше первой даты месяца
                  ConstDate @< FirstMonthDate
                ),
    % в список средних зп
    AvgSalaryList),
    % проверить список средних зп
    \+ AvgSalaryList = [],
    % последние данные средней зп за месяц
    last(AvgSalaryList, MonthAvgSalary),
    % взять расчетный коэфициент
    get_param(Scope, in, pAvgSalaryRB_Coef-AvgSalaryRB_Coef),
    % календарных дней в месяце
    month_days(Y, M, MonthDays),
    % расчитать среднедневную зп для месяца
    MonthAvgWage is round(MonthAvgSalary * AvgSalaryRB_Coef / MonthDays),
    !.

/**/

 %
%%

﻿%% twg_fee
% Зарплата и Отдел кадров -> Зарплата -> 02. Прочие доходы, расходы, льготы
%    04. Алименты
%    11. Штрафы
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
%#INCLUDE params
%#INCLUDE wg_data_mix
:- ['../common/lib', '../common/params', '../common/wg_data_mix'].
%#INCLUDE twg_fee_sql
:- [twg_fee_sql].
%#INCLUDE twg_fee_in_params
%:- [twg_fee_in_params].
%%

%% facts
:-  init_data,
    working_directory(_, 'kb'),
    [
    usr_wg_MovementLine,
    usr_wg_TblCharge,
    usr_wg_TblCharge_AlimonyDebt,
    usr_wg_FeeType,
    usr_wg_FeeType_Taxable,
    usr_wg_FeeType_Dict,
    usr_wg_TblCalLine,
    usr_wg_TblCal_FlexLine,
    usr_wg_FCRate,
    gd_const_budget,
    usr_wg_Variables,
    usr_wg_Alimony,
    usr_wg_TransferType,
    usr_wg_TransferScale,
    usr_wg_AlimonyDebt
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

/* реализация - расчет */
%param_list(wg_fee_alimony,in,[pEmplKey-147132195,pDateBegin-'2014-05-01',pTotalDocKey-150492516,pFeeTypeKey-147046709,pRoundType-2,pRoundValue-1.0]).

% расчет итогового начисления
fee_calc(Scope) :-
    % - для алиментов
    Scope = wg_fee_alimony,
    % для каждого сотрудника
    get_param_list(Scope, in, [pEmplKey-EmplKey]),
    % выполнить расчет
    fee_calc(Scope, EmplKey),
    % найти альтернативу
    fail.
fee_calc(_) :-
    % больше альтернатив нет
    !.

% выполнить расчет
fee_calc(Scope, EmplKey) :-
    % - для алиментов
    Scope = wg_fee_alimony,
    % удалить временные данные по расчету
    forall( get_param(Scope, temp, pEmplKey-EmplKey, Pairs),
            dispose_param_list(Scope, temp, Pairs) ),
    % расчет табеля
    calc_tab(Scope, EmplKey),
    % расчет суммы
    cacl_amount(Scope, EmplKey),
    % расчет формулы
    calc_formula(Scope, EmplKey),
    % расчет перевода
    cacl_transf(Scope, EmplKey),
    % расчет долгов
    calc_debt(Scope, EmplKey),
    % контроль остатка
    check_rest(Scope, EmplKey),
    % добавление начислений
    add_charges(Scope, EmplKey),
    !.

% расчет табеля
calc_tab(Scope, EmplKey) :-
    % - для алиментов
    Scope = wg_fee_alimony, Type = temp, Section = pAlimonyCalcTab,
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-Section-DT]),
    % последний прием на работу
    PK = [pEmplKey-EmplKey, pFirstMoveKey-_],
    get_last_hire(Scope, PK, DateIn),
    % начало итогового месяца
    get_param_list(Scope, in, [pEmplKey-EmplKey, pDateBegin-DateBegin]),
    DateBegin @>= DateIn,
    % табель за итоговый месяц
    atom_date(DateBegin, date(Y, M, _)),
    calc_month_tab(Scope, PK, Y-M, TabDays),
    sum_days_houres(TabDays, TDays, THoures),
    % спецификация временных данных
    append([ [Section-1], PK, [pYM-Y-M, pTDays-TDays, pTHoures-THoures] ],
                TPairs),
    % добавить временные данные
    new_param_list(Scope, Type, TPairs),
    % спецификация алиментов
    SpecAlimony = [
                fDocKey-AlimonyKey, fEmplKey-EmplKey,
                fDateBegin-ADateBegin, fDateEnd-ADateEnd ],
    % спецификация временных данных
    append([ [Section-2], PK,
             [pAlimonyKey-AlimonyKey, pDateBegin-ADateBegin, pDateEnd-ADateEnd],
             [pYM-Y-M, pTDays-ADays, pTHoures-AHoures, pTCoef-TCoef] ],
                APairs),
    % для всех алиментов
    forall( get_data(Scope, kb, usr_wg_Alimony, SpecAlimony),
            ( % посчитать дни и часы для периода действия алиментов
              sum_days_houres(TabDays, ADays, AHoures, ADateBegin, ADateEnd),
              % вычислить коеффициент от общего табеля за месяц
              TCoef is AHoures / THoures,
              % добавить временные данные
              new_param_list(Scope, Type, APairs)
            )
          ),
    !.

% расчет суммы
cacl_amount(Scope, EmplKey) :-
    % - для алиментов
    Scope = wg_fee_alimony, Type = temp, Section = pAlimonyCalcAmount,
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-Section-DT]),
    % собрать начисления по Группе начислений
    fee_group_charges(Scope, EmplKey, Charges),
    % Общая сумма
    charges_sum(Charges, AmountAll),
    % Исключаемые начисления
    charges_excl(Scope, EmplKey, Charges, ChargesExcl),
    % Исключаемая сумма
    charges_sum(ChargesExcl, [debit(1), credit(0)], AmountExcl),
    % Подоходный налог (ПН)
    get_data(Scope, kb, usr_wg_FeeType_Dict, [
                fID-IncomeTaxFeeType, fAlias-"ftIncomeTax" ]),
    charges_sum(Charges, [debit(0), credit(1)], [IncomeTaxFeeType], IncomeTax),
    % собрать виды начислений, облагаемые ПН
    findall( TaxableFeeType,
             get_data(Scope, kb, usr_wg_FeeType_Taxable, [
                         fEmplKey-EmplKey, fFeeTypeKey-TaxableFeeType ]),
    TaxableFeeTypeList),
    % Облагаемая ПН сумма
    charges_sum(Charges, [debit(1), credit(0)], TaxableFeeTypeList, AmountTaxable),
    % Коеффициент ПН
    IncomeTaxCoef is IncomeTax / AmountTaxable,
    % Облагаемая ПН Исключаемая сумма
    charges_sum(ChargesExcl, [debit(1), credit(0)], TaxableFeeTypeList, AmountTaxableExcl),
    % Исключаемый ПН
    IncomeTaxExcl is AmountTaxableExcl * IncomeTaxCoef,
    % Расчетная сумма = Общая сумма - Исключаемая сумма - Исключаемый ПН
    ForAlimony0 is AmountAll - AmountExcl - IncomeTaxExcl,
    to_currency(ForAlimony0, ForAlimony, 0),
    % спецификация временных данных
    Pairs = [
        Section-1, pEmplKey-EmplKey, pForAlimony-ForAlimony,
        pAmountAll-AmountAll, pAmountExcl-AmountExcl, pIncomeTaxExcl-IncomeTaxExcl,
        pAmountTaxableExcl-AmountTaxableExcl, pIncomeTaxCoef-IncomeTaxCoef,
        pIncomeTax-IncomeTax, pAmountTaxable-AmountTaxable ],
    % добавить временные данные
    new_param_list(Scope, Type, Pairs),
    !.

% расчет формулы
calc_formula(Scope, EmplKey) :-
    % - для алиментов
    Scope = wg_fee_alimony, Type = temp, Section = pAlimonyCalcFormula,
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-Section-DT]),
    true,
    !.

% расчет перевода
cacl_transf(Scope, EmplKey) :-
    % - для алиментов
    Scope = wg_fee_alimony, Type = temp, Section = pAlimonyCalcTransfer,
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-Section-DT]),
    true,
    !.

% процент для вида начислений "Расходы по переводу"
get_transf_percent(Scope, EmplKey, TransferTypeKey, Sum, Percent) :-
    get_param_list(Scope, run, [pEmplKey-EmplKey, pDateCalcTo-DateCalcTo]),
    findall( TransferData,
             get_transf_type(Scope, DateCalcTo, TransferTypeKey, TransferData),
    TransferDataList),
    msort(TransferDataList, TransferDataList1),
    last(TransferDataList1, _-TransferTypeKey1),
    get_transf_scale(Scope, TransferTypeKey1, Sum, Percent),
    !.
get_transf_percent(_, _, _, _, 0.0) :-
    !.

% Расценки на перевод
get_transf_type(Scope, DateCalcTo, TransferTypeKey0, DateBegin-TransferTypeKey) :-
    get_data(Scope, kb, usr_wg_TransferType, [
                fID-TransferTypeKey, fParent-TransferTypeKey0,
                fDateBegin-DateBegin ]),
    \+ get_data(Scope, kb, usr_wg_TransferType, [
                    fParent-TransferTypeKey]),
    DateBegin @< DateCalcTo.
get_transf_type(Scope, DateCalcTo, TransferTypeKey0, TransferTypeKey) :-
    get_data(Scope, kb, usr_wg_TransferType, [
                fID-TransferTypeKey1, fParent-TransferTypeKey0 ]),
    get_transf_type(Scope, DateCalcTo, TransferTypeKey1, TransferTypeKey).

% Шкала расценок
get_transf_scale(Scope, TransferTypeKey, Sum, Percent) :-
    findall( StartSum-Percent0,
             ( get_data(Scope, kb, usr_wg_TransferScale, [
                         fTranferTypeKey-TransferTypeKey,
                         fStartSum-StartSum, fPercent-Percent0 ]),
               Sum >= StartSum ),
    ScaleDataList),
    msort(ScaleDataList, ScaleDataList1),
    last(ScaleDataList1, _-Percent),
    !.
get_transf_scale(_, _, _, 0.0) :-
    !.

% собрать начисления по Группе начислений
fee_group_charges(Scope, EmplKey, Charges) :-
    % спецификация для начислений
    SpecTblCharge =  [
        fEmplKey-EmplKey,
        fCalYear-Y, fCalMonth-M, fDateBegin-DateBegin,
        fDebit-Debit, fCredit-Credit,
        fFeeTypeKey-FeeTypeKey ],
    % спецификация для группы начислений
    SpecFeeType =  [
        fEmplKey-EmplKey, fFeeTypeKey-FeeTypeKey ],
    % спецификация данных начисления
    ChargeData = [
        Y-M, DateBegin, Debit, Credit, FeeTypeKey ],
    % взять данные
    findall( ChargeData,
              % по начислениям
            ( get_data(Scope, kb, usr_wg_TblCharge, SpecTblCharge),
              % с наличием суммы
              once( ( \+ Debit =:= 0 ; \+ Credit =:= 0 ) ),
              % и соответствующего типа
              get_data(Scope, kb, usr_wg_FeeType, SpecFeeType)
            ),
    % в список
    Charges ),
    !.

% исключаемые начисления
charges_excl(Scope, EmplKey, Charges, ChargesExcl) :-
    % спецификация данных начисления
    ChargeData = [
        _-_, DateBegin, _, _, FeeTypeKey ],
    % собрать исключаемые начисления
    findall( ChargeData,
             ( member(ChargeData, Charges),
               is_fee_type_excl(Scope, EmplKey, DateBegin, FeeTypeKey)
             ),
    ChargesExcl ),
    !.

% сумма начислений
charges_sum(Charges, Amount) :-
    charges_sum(Charges, [], [], 0, Amount),
    !.
%
charges_sum(Charges, Options, Amount) :-
    charges_sum(Charges, Options, [], 0, Amount),
    !.
%
charges_sum(Charges, Options, ValidFeeTypes, Amount) :-
    charges_sum(Charges, Options, ValidFeeTypes, 0, Amount),
    !.
%
charges_sum([], _, _, Amount, Amount) :-
    !.
charges_sum([Charge|Charges], Options, ValidFeeTypes, Amount0, Amount) :-
    charge_acc(Charge, Options, ValidFeeTypes, Amount0, Amount1),
    !,
    charges_sum(Charges, Options, ValidFeeTypes, Amount1, Amount).

% накопление суммы начислений
charge_acc(ChargeData, Options, ValidFeeTypes, Amount0, Amount1) :-
    % спецификация данных
    ChargeData = [
        _-_, _, Debit, Credit, FeeTypeKey ],
    % если тип начисления дейсвителен
    ( ValidFeeTypes = [] ; memberchk(FeeTypeKey, ValidFeeTypes) ),
    % установить опции
    ( memberchk(debit(InclDebit), Options) ; InclDebit = 1 ),
    ( memberchk(credit(InclCredit), Options) ; InclCredit = 1 ),
    % и произвести накопление
    Amount1 is Amount0 + Debit * InclDebit - Credit * InclCredit,
    !.
charge_acc(_, _, _, Amount, Amount) :-
    !.

% тип начисления исключается из расчета
is_fee_type_excl(Scope, EmplKey, DateBegin, FeeTypeKey) :-
    % - для алиментов
    Scope = wg_fee_alimony,
    % если вид начисления "Компенсация отпуска"
    get_data(Scope, kb, usr_wg_FeeType_Dict, [
                fID-FeeTypeKey, fAlias-Alias ]),
    memberchk(Alias, ["ftHolidayComp"]),
    % и сотрудник уволен в месяце текущей даты
    is_fired(Scope, EmplKey, DateBegin),
    !.

% сотрудник уволен в месяце текущей даты
is_fired(Scope, EmplKey, DateBegin) :-
    atom_date(DateBegin, date(Y, M, _)),
    get_data(Scope, kb, usr_wg_MovementLine, [
                fEmplKey-EmplKey,
                fMoveYear-Y, fMoveMonth-M,
                fMovementType-3 ]),
    !.

% сопоставить с данными по умолчанию
fit_data(Scope, [Name-Value0], [Name-Value]) :-
    % - для алиментов (Процент остатка, Процент списания долга)
    Scope = wg_fee_alimony, Type = fit,
    memberchk(Name, [pRestPercent, pPercent]),
    ( Value0 > 0, Value = Value0 ; get_param(Scope, Type, Name-Value) ),
    !.
fit_data(Scope, Pairs0, Pairs) :-
    % - для алиментов (Процент от БПМ)
    Scope = wg_fee_alimony, Type = fit,
    Pairs0 = [pChildeCount-ChildCount, pLivingWagePerc-LivingWagePerc0],
    Pairs = [pChildeCount-ChildCount, pLivingWagePerc-LivingWagePerc],
    ( LivingWagePerc0 > 0, LivingWagePerc = LivingWagePerc0
    ; Pairs1 = [pChildQtyCmp-ChildQtyCmp, pLivingWagePerc-LivingWagePerc1],
      get_param_list(Scope, Type, Pairs1),
      catch( atomic_concat(ChildCount, ChildQtyCmp, Atom), _, fail ),
      catch( term_to_atom(Term, Atom), _, fail),
      catch( Term, _, fail),
      LivingWagePerc = LivingWagePerc1 ),
    !.
fit_data(_, Pairs, Pairs) :-
    !.

/* реализация - расширение для клиента */

% загрузка входных данных по сотруднику
fee_calc_in(Scope, EmplKey, DateBegin, TotalDocKey, FeeTypeKey, RoundType, RoundValue) :-
    Scope = wg_fee_alimony, Type = in, Section = pEmplKey,
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-Section-DT]),
    % записать входные параметры
    new_param_list(Scope, Type, [
        pEmplKey-EmplKey, pDateBegin-DateBegin,
        pTotalDocKey-TotalDocKey, pFeeTypeKey-FeeTypeKey,
        pRoundType-RoundType, pRoundValue-RoundValue
        ]),
    !.
    
% подготовка данных выполнения
fee_calc_prep(Scope) :-
    Scope = wg_fee_alimony, Type = in, TypeNextStep = run,
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-TypeNextStep-DT]),
    % для каждого сотрудника
    get_param_list(Scope, Type, [pEmplKey-_, pDateBegin-DateBegin], Pairs),
    % собрать входные данные
    findall( Pairs0,
             ( member(Template, [pCommon-1, pAlimony-1]),
               get_param_list(Scope, Type, [Template], Pairs0)
             ),
    PairsList ),
    append(PairsList, PairsNextStep0),
    % сформировать данные выполнения
    atom_date(DateBegin, date(Y, M, _)),
    atom_date(DateCalcFrom, date(Y, M, 1)),
    date_add(DateBegin, 1, month, DateBegin1),
    atom_date(DateBegin1, date(Y1, M1, _)),
    atom_date(DateCalcTo, date(Y1, M1, 1)),
    % записать данные выполнения
    append([Pairs,
            [pDateCalcFrom-DateCalcFrom, pDateCalcTo-DateCalcTo],
            PairsNextStep0],
                PairsNextStep),
    new_param_list(Scope, TypeNextStep, PairsNextStep),
    % найти альтернативу
    fail.
fee_calc_prep(_) :-
    % больше альтернатив нет
    !.

% выгрузка данных выполнения по сотруднику
fee_calc_run(Scope, EmplKey) :-
    Scope = wg_fee_alimony, Type = run, Section = PK,
    % первичный ключ
    PK = [pEmplKey-EmplKey],
    % взять данные выполнения
    get_param_list(Scope, Type, PK),
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-Section-DT]).

% формирование SQL-запросов по сотруднику
fee_calc_sql(Scope, EmplKey, PredicateName, Arity, SQL) :-
    Scope = wg_fee_alimony, Type = run, TypeNextStep = query,
    % взять локальное время
    get_local_date_time(DT),
    % записать отладочную информацию
    new_param_list(Scope, debug, [Scope-Type-TypeNextStep-DT]),
    % взять данные выполнения для подстановки параметров
    get_param_list(Scope, Type, [pEmplKey-EmplKey], Pairs),
    % для каждой спецификации набора данных
    gd_pl_ds(Scope, kb, PredicateName, Arity, _),
    Query = PredicateName/Arity,
    is_valid_sql(Query),
    % взять SQL-строку с параметрами
    get_sql(Scope, kb, Query, SQL0, Params),
    % сопоставить параметры с данными выполнения
    member_list(Params, Pairs),
    % подготовить SQL-запрос
    prepare_sql(SQL0, Params, SQL),
    % записать данные по SQL-запросу
    PairsNextStep = [pEmplKey-EmplKey, pQuery-Query, pSQL-SQL],
    new_param_list(Scope, TypeNextStep, PairsNextStep).

/**/

 %
%%

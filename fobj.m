function f = fobj(x, simu_para)

% === Input parameters from simu_para ===
lgZV1 = simu_para{1};       % Elevation-storage curve of reservoir 1
lgZQ1 = simu_para{2};       % Discharge-elevation curve of reservoir 1
lgZV2 = simu_para{3};       % Elevation-storage curve of reservoir 2
lgZQ2 = simu_para{4};       % Discharge-elevation curve of reservoir 2
inflow1 = simu_para{5};     % Inflow to reservoir 1
QJR = simu_para{6};         % Natural inflow between reservoir 1 and 2
QJ1 = simu_para{7};         % Inflow from tributary to node 1
QJ2 = simu_para{8};         % Inflow from tributary to node 2
QJ3 = simu_para{9};         % Inflow from tributary to node 3
V_upper1 = simu_para{10};   % Upper storage bound for reservoir 1
V_lower1 = simu_para{11};   % Lower storage bound for reservoir 1
V_upper2 = simu_para{12};   % Upper storage bound for reservoir 2
V_lower2 = simu_para{13};   % Lower storage bound for reservoir 2
IRRCOE = simu_para{14};     % Irrigation water demand coefficients (%)
lgHN1 = simu_para{15};      % Head-power mapping of reservoir 1
lgHN2 = simu_para{16};      % Head-power mapping of reservoir 2

% Parameters moved from constants to input
IRRTZ = simu_para{17};      % Storage for Thailand (10^8 m³)
IRRLZ = simu_para{18};      % Storage for Laos (10^8 m³)
IRRCZ = simu_para{19};      % Storage for Cambodia (10^8 m³)
IRRVZ = simu_para{20};      % Storage for Vietnam (10^8 m³)
alloc_coef = simu_para{21};  % Allocation coefficient for irrigation (e.g., 0.7)
score_para = simu_para{22};  % Parameters for score function: [a, b, c, d]
crop_para = simu_para{23};   % Yield and price parameters: [YT, YL, YJ, YY, AT, AL, AJ, AY]

% Constants
DT = 60 * 60 * 24 * 30.4;
DW = 1e8;

% Irrigation demand (converted to m³/s)
QRM1 = (IRRTZ * DW .* IRRCOE(1,:) / 100) ./ DT;
QRM2 = (IRRLZ * DW .* IRRCOE(2,:) / 100) ./ DT;
QRM3 = (IRRCZ * DW .* IRRCOE(3,:) / 100) ./ DT;
QRM4 = (IRRVZ * DW .* IRRCOE(4,:) / 100) ./ DT;

% Decision variables
Qo1 = x(1:12);  Qo2 = x(13:24);
Qo3 = x(25:36); Qo4 = x(37:48);
Qo5 = x(49:60); Qo6 = x(61:72);

% Initialization
SimuPeriod = 12;
Z1 = zeros(SimuPeriod+1,1); V1 = Z1; H1 = zeros(SimuPeriod,1); Qe1 = H1; Qs1 = H1; P1 = H1;
Z2 = Z1; V2 = Z1; H2 = H1; Qe2 = H1; Qs2 = H1; P2 = H1;
IRRT = H1; IRRL = H1; IRRJ = H1; IRRY = H1;

% Initial water level and storage
Z1(1) = simu_para{24}; Z2(1) = simu_para{25};
Z1(13) = simu_para{26}; Z2(13) = simu_para{27};
V1(1) = chazhi1(lgZV1(:,1), lgZV1(:,2), Z1(1));
V2(1) = chazhi1(lgZV2(:,1), lgZV2(:,2), Z2(1));
V1(13) = chazhi1(lgZV1(:,1), lgZV1(:,2), Z1(13));
V2(13) = chazhi1(lgZV2(:,1), lgZV2(:,2), Z2(13));

% Head loss coefficient
K = 8.6;

% Coefficients for score function
a = score_para(1); b = score_para(2); c = score_para(3); d = score_para(4);

% Loop over simulation period
for ii = 1:SimuPeriod
    % Reservoir 1 mass balance
    if ii == 12
        V1(ii+1) = V1(13);
    else
        V1(ii+1) = V1(ii) + (inflow1(ii) - Qo1(ii)) * DT / DW;
    end
    V1(ii+1) = max(min(V1(ii+1), V_upper1(ii)), V_lower1(ii));
    Z1(ii+1) = chazhi1(lgZV1(:,2), lgZV1(:,1), V1(ii+1));
    Qo1(ii) = inflow1(ii) - (V1(ii+1) - V1(ii)) * DW / DT;

    % Reservoir 2 mass balance
    if ii == 12
        V2(ii+1) = V2(13);
    else
        V2(ii+1) = V2(ii) + (Qo1(ii) + QJR(ii) - Qo2(ii)) * DT / DW;
    end
    V2(ii+1) = max(min(V2(ii+1), V_upper2(ii)), V_lower2(ii));
    Z2(ii+1) = chazhi1(lgZV2(:,2), lgZV2(:,1), V2(ii+1));
    Qo2(ii) = Qo1(ii) + QJR(ii) - (V2(ii+1) - V2(ii)) * DW / DT;

    % Reservoir 1 hydropower
    z_upper1 = 0.5 * (Z1(ii) + Z1(ii+1));
    z_lower1 = chazhi1(lgZQ1(:,2), lgZQ1(:,1), Qo1(ii));
    H1(ii) = z_upper1 - z_lower1 - 1;
    power_limit1 = chazhi1(lgHN1(:,1), lgHN1(:,2), H1(ii));
    P1(ii) = K * Qo1(ii) * H1(ii) / 1e3;
    P1(ii) = min(P1(ii), power_limit1);
    Qe1(ii) = P1(ii) * 1e3 / (K * H1(ii));
    Qs1(ii) = max(Qo1(ii) - Qe1(ii), 0);

    % Reservoir 2 hydropower
    z_upper2 = 0.5 * (Z2(ii) + Z2(ii+1));
    z_lower2 = chazhi1(lgZQ2(:,2), lgZQ2(:,1), Qo2(ii));
    H2(ii) = z_upper2 - z_lower2 - 1;
    power_limit2 = chazhi1(lgHN2(:,1), lgHN2(:,2), H2(ii));
    P2(ii) = K * Qo2(ii) * H2(ii) / 1e3;
    P2(ii) = min(P2(ii), power_limit2);
    Qe2(ii) = P2(ii) * 1e3 / (K * H2(ii));
    Qs2(ii) = max(Qo2(ii) - Qe2(ii), 0);

    % Thailand and Laos irrigation
    QAIRR1 = (Qo2(ii) + QJ1(ii)) * alloc_coef;
    QZX1 = QRM1(ii) + QRM2(ii);
    QIT = QAIRR1 * QRM1(ii) / QZX1;
    QIL = QAIRR1 * QRM2(ii) / QZX1;
    Qo3(ii) = min(Qo3(ii), QIT);
    Qo4(ii) = min(Qo4(ii), QIL);
    IRR3 = min(Qo3(ii) / QRM1(ii), 1);
    IRR4 = min(Qo4(ii) / QRM2(ii), 1);
    IRRT(ii) = score_curve(IRR3, a, b, c, d);
    IRRL(ii) = score_curve(IRR4, a, b, c, d);

    % Cambodia irrigation
    QAIRR2 = (QAIRR1 / alloc_coef - Qo3(ii) - Qo4(ii) + QJ2(ii)) * alloc_coef;
    Qo5(ii) = min(Qo5(ii), QRM3(ii));
    IRR5 = min(Qo5(ii) / QRM3(ii), 1);
    IRRJ(ii) = score_curve(IRR5, a, b, c, d);

    % Vietnam irrigation
    QAIRR3 = (QAIRR2 / alloc_coef - Qo5(ii) + QJ3(ii)) * alloc_coef;
    Qo6(ii) = min(Qo6(ii), QRM4(ii));
    IRR6 = min(Qo6(ii) / QRM4(ii), 1);
    IRRY(ii) = score_curve(IRR6, a, b, c, d);
end

% Power generation benefit (USD)
f1 = (mean(P1) + mean(P2)) * 1e3 * 12 * 30.4 * 24 / 1e8 * 0.08;

% Irrigation benefit (USD)
YT = crop_para(1); YL = crop_para(2); YJ = crop_para(3); YY = crop_para(4);
AT = crop_para(5); AL = crop_para(6); AJ = crop_para(7); AY = crop_para(8);
f2 = (min(IRRT)*YT*AT*Parameters1 + min(IRRL)*YL*AL*Parameters2 + min(IRRJ)*YJ*AJ*Parameters3 + min(IRRY)*YY*AY*Parameters4) / 1e8;

f = [-f1, -f2];  % Negative for minimization
end

function score = score_curve(ratio, a, b, c, d)
if ratio < 0.1
    score = 0;
else
    score = a * ratio^3 + b * ratio^2 + c * ratio + d;
    score = min(score, 1);
end
end

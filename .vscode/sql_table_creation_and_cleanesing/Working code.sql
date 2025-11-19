select * from MasterTenders_10_1
SELECT * FROM public.rawdata_2025_10_1;
CREATE TABLE public.RawData_2025_10_1 (
    TenderSubject TEXT,                 -- Предмет тендера
    SearchQuery TEXT,                   -- Поиск
    TenderNumber TEXT,                  -- Номер тендера (X_ID)
    Region TEXT,                        -- Регион
    DeliveryPlace TEXT,                 -- Место поставки
    InitialPriceRub TEXT,               -- Начальная цена, руб (X1)
    AdvancePayment TEXT,                -- Аванс
    BidSecurityRub TEXT,                -- Обеспечение заявки, руб
    ContractSecurityRub TEXT,           -- Обеспечение контракта, руб
    CustomerName TEXT,                  -- Заказчик
    CustomerINN TEXT,                   -- ИНН заказчика (X3)
    OrganizerContactPerson TEXT,        -- Контактное лицо организатора
    OrganizerPhone TEXT,                -- Телефон организатора
    OrganizerEmail TEXT,                -- Электронная почта организатора
    OrganizerFax TEXT,                  -- Факс организатора
    SourceLink TEXT,                    -- Ссылка на источник
    EISNumber TEXT,                     -- Номер ЕИС
    ETPNumber TEXT,                     -- Номер ЭТП
    PurchaseType TEXT,                  -- Тип закупки
    PlacementMethod TEXT,               -- Способ размещения
    Stage TEXT,                         -- Этап
    PublicationDateMSK TEXT,            -- Дата публикации (МСК)
    ChangeDateMSK TEXT,                 -- Дата изменения (МСК)
    EndDateMSK TEXT,                    -- Дата окончания (МСК)
    OfferDeadlineMSK TEXT,              -- Окончание подачи предложений (МСК)
    BiddingStartTimeMSK TEXT,           -- Начало торгов (МСК)
    BiddingEndTimeMSK TEXT,             -- Завершение торгов (МСК)
    ResultsDateMSK TEXT,                -- Подведение итогов (МСК) (X8)
    ApplicationsCount TEXT,             -- Количество заявок (X2)
    RejectedApplicationsCount TEXT,     -- Количество отклонённых заявок
    MinimumPriceDeclared TEXT,          -- Минимальная заявленная цена
    WinnerName TEXT,                    -- Победитель
    WinnerINN TEXT,                     -- ИНН победителя (X4)
    WinnerPhone TEXT,                   -- Телефон победителя
    WinnerEmail TEXT,                   -- Электронная почта победителя
    WinnerPriceRub TEXT,                -- Цена победителя, руб
    ContractPriceRub TEXT,              -- Цена контракта, руб (Y)
    Tags TEXT,                          -- Метки (X6)
    LastComment TEXT,                   -- Последний комментарий
    Sectors TEXT                        -- Отрасли
);
CREATE TABLE MasterTenders_10_1 (
    TenderID TEXT PRIMARY KEY,       -- Уникальный номер тендера (Ключ)
    NMCK_X1 NUMERIC,                 -- Начальная цена (число)
    FinalPrice_Y NUMERIC,            -- Цена победителя (число)
    CustomerINN_X3 TEXT,             -- ИНН заказчика
    WinnerINN_X4 TEXT,               -- ИНН победителя
    Participants_X2 INTEGER,         -- Количество заявок (целое число)
    TenderSubject_X6 TEXT,           -- Предмет тендера (Метки)
    ContractDate_X8 DATE             -- Дата подведения итогов (дата)
);

-- СКРИПТ 1.2: ОЧИСТКА, ТРАНСФОРМАЦИЯ И ВСТАВКА ДАННЫХ (Финальная версия)

-- 1. Удаляем предыдущие данные, чтобы избежать ошибок дублирования и проверить новую логику

-- СКРИПТ 1.2 (ОБНОВЛЕННЫЙ): Вставка с обработкой дубликатов

INSERT INTO MasterTenders_10_1 ( 
    TenderID, NMCK_X1, FinalPrice_Y, CustomerINN_X3, WinnerINN_X4, Participants_X2, TenderSubject_X6, ContractDate_X8
)
SELECT 
    TRIM(T.TenderNumber) AS TenderID, 
    -- ... (Остальные преобразования X1, Y, X3, X4, X2, X6, X8 остаются без изменений) ...
    CAST(REPLACE(REPLACE(T.InitialPriceRub, ' ₽', ''), ' ', '') AS NUMERIC) AS NMCK_X1, 
    CAST(REPLACE(REPLACE(T.ContractPriceRub, ' ₽', ''), ' ', '') AS NUMERIC) AS FinalPrice_Y,
    TRIM(TO_CHAR(CAST(REPLACE(T.CustomerINN, ',', '.') AS DECIMAL), 'FM999999999999999999')) AS CustomerINN_X3,
    TRIM(TO_CHAR(CAST(REPLACE(T.WinnerINN, ',', '.') AS DECIMAL), 'FM999999999999999999')) AS WinnerINN_X4,
    CAST(T.ApplicationsCount AS INTEGER) AS Participants_X2,
    COALESCE(T.Tags, T.TenderSubject) AS TenderSubject_X6,
    COALESCE(
        TO_DATE(SUBSTRING(REPLACE(T.ResultsDateMSK, 'по ', ''), 1, 10), 'DD.MM.YYYY'),
        TO_DATE(SUBSTRING(REPLACE(T.BiddingEndTimeMSK, 'по ', ''), 1, 10), 'DD.MM.YYYY')
    ) AS ContractDate_X8

FROM 
    public.RawData_2025_10_1 T

-- Дополнительная фильтрация (не удаляйте её!)
WHERE 
    T.ContractPriceRub IS NOT NULL AND TRIM(REPLACE(T.ContractPriceRub, ' ₽', '')) != '0'
    AND T.InitialPriceRub IS NOT NULL
    AND T.WinnerINN IS NOT NULL AND TRIM(T.WinnerINN) != ''
    AND (COALESCE(T.Tags, T.TenderSubject) IS NOT NULL AND TRIM(COALESCE(T.Tags, T.TenderSubject)) != '')

-- !!! НОВЫЙ ЭЛЕМЕНТ: ОБРАБОТКА КОНФЛИКТОВ !!!
ON CONFLICT (TenderID) 
DO NOTHING;

COMMIT;
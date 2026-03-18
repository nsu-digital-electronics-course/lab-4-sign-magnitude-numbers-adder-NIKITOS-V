module sign_magnitude_adder #(
    parameter SIZE = 4  // Разрядность чисел (включая знак)
) (
    input  logic [SIZE-1:0] a,  // Первое слагаемое (sign-magnitude)
    input  logic [SIZE-1:0] b,  // Второе слагаемое (sign-magnitude)
    output logic [SIZE-1:0] s,  // Результат (sign-magnitude)
    output logic overflow       // Флаг переполнения
);

    // Разрядность модуля числа (без знака)
    localparam MAG_WIDTH = SIZE - 1;

    // Разделяем входные числа на знак и модуль
    logic a_sign, b_sign;
    logic [MAG_WIDTH-1:0] a_mag, b_mag;

    assign a_sign = a[SIZE-1];
    assign b_sign = b[SIZE-1];
    assign a_mag = a[MAG_WIDTH-1:0];
    assign b_mag = b[MAG_WIDTH-1:0];

    // Промежуточные сигналы
    logic [MAG_WIDTH-1:0] sum_mag;       // Результирующий модуль
    logic result_sign;                    // Знак результата
    logic [MAG_WIDTH:0] add_result;       // Результат сложения модулей (с дополнительным битом для переполнения)
    logic [MAG_WIDTH-1:0] sub_result;     // Результат вычитания модулей
    logic greater_a;                       // Флаг: модуль A больше или равен модулю B
    logic cin;                              // Сигнал заема при вычитании

    // Сравнение модулей (A >= B)
    assign greater_a = (a_mag >= b_mag);

    // Сложение модулей (используется когда знаки одинаковые)
    assign add_result = a_mag + b_mag;

    // Вычитание модулей (используется когда знаки разные)
    // Всегда вычитаем из большего меньшее
    assign {cin, sub_result} = greater_a ? 
                                ({1'b0, a_mag} - {1'b0, b_mag}) : 
                                ({1'b0, b_mag} - {1'b0, a_mag});

    // Основная логика сумматора
    always_comb begin
        // Значения по умолчанию
        result_sign = 1'b0;
        sum_mag = {MAG_WIDTH{1'b0}};
        overflow = 1'b0;

        if (a_sign == b_sign) begin
            // Случай 1: Знаки одинаковые (оба положительные или оба отрицательные)
            // Выполняем сложение модулей
            sum_mag = add_result[MAG_WIDTH-1:0];
            result_sign = a_sign; // Знак результата совпадает со знаком операндов
            
            // Проверка переполнения: если старший бит результата сложения (индекс MAG_WIDTH) равен 1
            overflow = add_result[MAG_WIDTH];
            
        end else begin
            // Случай 2: Знаки разные (вычитание модулей)
            
            // Результат вычитания модулей
            sum_mag = sub_result;
            
            // Знак результата равен знаку того числа, чей модуль больше
            result_sign = greater_a ? a_sign : b_sign;
            
            // При вычитании переполнения в классическом смысле нет,
            // но может быть заем, который нас не интересует, так как мы вычитаем правильно.
            overflow = 1'b0;
        end

        // Формирование выходного числа
        s[SIZE-1] = result_sign;
        s[MAG_WIDTH-1:0] = sum_mag;
    end

    // Нормализация нуля: если модуль результата равен 0, устанавливаем знак в 0 (+0)
    always_comb begin
        if (s[MAG_WIDTH-1:0] == {MAG_WIDTH{1'b0}}) begin
            s[SIZE-1] = 1'b0; // Принудительно ставим знак плюс
        end
    end

endmodule
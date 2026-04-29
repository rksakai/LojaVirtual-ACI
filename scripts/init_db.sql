-- Executar no Azure SQL via portal ou sqlcmd

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ProdutosDB')
    CREATE DATABASE ProdutosDB;
GO

USE ProdutosDB;
GO

IF NOT EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Produtos'
)
BEGIN
    CREATE TABLE Produtos (
        id          INT IDENTITY(1,1) PRIMARY KEY,
        nome        NVARCHAR(200)  NOT NULL,
        descricao   NVARCHAR(1000) NOT NULL,
        valor       DECIMAL(10, 2) NOT NULL,
        ativo       BIT            NOT NULL DEFAULT 1,
        criado_em   DATETIME2      NOT NULL DEFAULT GETDATE()
    );

    INSERT INTO Produtos (nome, descricao, valor) VALUES
        ('Notebook Pro 15',  'Intel Core i7, 16GB RAM, SSD 512GB',          4999.90),
        ('Mouse Sem Fio',    'Mouse ergonômico wireless com DPI ajustável',   149.90),
        ('Teclado Mecânico', 'Teclado mecânico RGB com switches Blue',        299.90),
        ('Monitor 27"',      'Monitor Full HD IPS 75Hz',                     1299.90),
        ('Headset Gamer',    'Som surround 7.1 e microfone removível',        399.90);
END
GO
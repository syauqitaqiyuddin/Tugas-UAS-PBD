CREATE TABLE Customer (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL
);


CREATE TABLE Room (
  id INT PRIMARY KEY AUTO_INCREMENT,
  room_number INT NOT NULL,
  type VARCHAR(50) NOT NULL,
  price DECIMAL(8, 2) NOT NULL
);


CREATE TABLE Reservation (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  room_id INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES Customer(id),
  CONSTRAINT fk_room FOREIGN KEY (room_id) REFERENCES Room(id)
);


CREATE TABLE HotelFacility (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL
);


CREATE TABLE FacilityReservation (
  id INT PRIMARY KEY AUTO_INCREMENT,
  reservation_id INT NOT NULL,
  facility_id INT NOT NULL,
  CONSTRAINT fk_reservation FOREIGN KEY (reservation_id) REFERENCES Reservation(id),
  CONSTRAINT fk_facility FOREIGN KEY (facility_id) REFERENCES HotelFacility(id)
);


CREATE TABLE ReservationDetail (
  id INT PRIMARY KEY AUTO_INCREMENT,
  facility_reservation_id INT NOT NULL,
  hotel_facility_id INT NOT NULL,
  CONSTRAINT fk_facility_reservation FOREIGN KEY (facility_reservation_id) REFERENCES FacilityReservation(id),
  CONSTRAINT fk_hotel_facility FOREIGN KEY (hotel_facility_id) REFERENCES HotelFacility(id)
);


CREATE TABLE Transaksi (
  id INT PRIMARY KEY AUTO_INCREMENT,
  reservation_id INT NOT NULL,
  facility_id INT NOT NULL,
  room_price DECIMAL(8, 2) NOT NULL,
  CONSTRAINT fk_reservation FOREIGN KEY (reservation_id) REFERENCES Reservation(id),
  CONSTRAINT fk_facility FOREIGN KEY (facility_id) REFERENCES HotelFacility(id)
);



-- Complex Query 1 untuk menghitung total pendapatan dari pengunjung.
SELECT
  SUM(total_price) AS total_money_gained
FROM (
  SELECT
    t.room_price * DATEDIFF(r.end_date, r.start_date) AS total_price
  FROM
    Transaksi t
  JOIN
    Reservation r ON t.reservation_id = r.id
) AS subquery;


-- Complex Query 2  menampilkan pengunjung dengan pengeluaran terbesar.
SELECT c.name, SUM(t.room_price) AS total_spent
FROM Customer c
JOIN Reservation r ON c.id = r.customer_id
JOIN Transaksi t ON r.id = t.reservation_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 5;


-- Complex Query 3 menampilkan pengunjung yang mengabiskan lebih dari 200$
SELECT r.id AS reservation_id, c.name AS customer_name, SUM(t.room_price) AS total_price
FROM Reservation r
JOIN Customer c ON r.customer_id = c.id
JOIN Transaksi t ON r.id = t.reservation_id
GROUP BY r.id, c.name
HAVING SUM(t.room_price) > 200;


-- View 1 menampilkan reservasi berdasarkan tanggal.
CREATE VIEW ReservationsByDate AS
SELECT r.id AS reservation_id, r.start_date, r.end_date, c.name AS customer_name
FROM Reservation r
JOIN Customer c ON r.customer_id = c.id
ORDER BY r.start_date;

-- View 2 menampilkan status ketersediaaan kamar
CREATE VIEW RoomAvailability AS
SELECT r.room_number, r.type, r.price, 
       CASE WHEN r.id IN (SELECT room_id FROM Reservation) THEN 'Not Available' ELSE 'Available' END AS availability
FROM Room r;

-- View 3 menampilkan total pendapatan hotel
CREATE VIEW keuntungan AS
SELECT r.id AS reservation_id, r.start_date, r.end_date, c.name AS customer_name, SUM(t.room_price) AS total_price
FROM Reservation r
JOIN Customer c ON r.customer_id = c.id
JOIN Transaksi t ON r.id = t.reservation_id
GROUP BY r.id, r.start_date, r.end_date, c.name
ORDER BY r.start_date;



-- Prosedur untuk memeriksa ketersediaan kamar pada rentang tanggal tertentu;
DELIMITER //

CREATE PROCEDURE CheckRoomAvailability (IN roomNumber INT, IN startDate DATE, IN endDate DATE)
BEGIN
    DECLARE isAvailable INT;

    SELECT COUNT(*) INTO isAvailable
    FROM Reservation
    WHERE room_id = roomNumber
        AND start_date <= endDate
        AND end_date >= startDate;

    IF isAvailable = 0 THEN
        SELECT CONCAT('Room ', roomNumber, ' is available .') AS availability;
    ELSE
        SELECT CONCAT('Room ', roomNumber, ' is not available. ') AS availability;
    END IF;
END //

DELIMITER ;
-- test 
CALL CheckRoomAvailability(101, '2023-06-21', '2023-06-23');


-- Fungsi untuk menampilkan harga total 
BEGIN
    DECLARE totalPrice DECIMAL(10,2);

    -- menghitung lama menginap
    SET @startDate = (SELECT start_date FROM Reservation WHERE id = reservationId);
    SET @endDate = (SELECT end_date FROM Reservation WHERE id = reservationId);
    SET @numDays = DATEDIFF(@endDate, @startDate) + 1;

    -- get harga kamar per/ hari
    SET @roomId = (SELECT room_id FROM Reservation WHERE id = reservationId);
    SET @roomPrice = (SELECT price FROM Room WHERE id = @roomId);

    -- Calculate the total price
    SET totalPrice = @numDays * @roomPrice;

    -- Return the total price
    RETURN totalPrice;
END

-- Trigger 1 trigger untuk mengubah status ketersediaan kamar saat dipesan
BEGIN
    DECLARE roomCount INT;

    -- Check nomor reservasi untuk kamar
    SELECT COUNT(*) INTO roomCount
    FROM Reservation
    WHERE room_id = NEW.room_id
        AND start_date <= NEW.end_date
        AND end_date >= NEW.start_date;

    -- kemudian update
    IF roomCount = 0 THEN
        UPDATE Room
        SET availability = 'Not Available'
        WHERE id = NEW.room_id;
    END IF;
END


-- Trigger 2 membuat proses pembayaran
BEGIN
    DECLARE totalAmount DECIMAL(10, 2);
    
    -- hitung jumlah hari menginap
    SET totalAmount = (SELECT CalculateTotalPrice(NEW.room_id, NEW.start_date, NEW.end_date, 0.0));

    -- masukkan record baru kedalam tabel
    INSERT INTO Payment (reservation_id, amount, payment_date)
    VALUES (NEW.id, totalAmount, NOW());
END
-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 20, 2023 at 05:40 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `booking_hotel`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CheckRoomAvailability` (IN `roomNumber` INT, IN `startDate` DATE, IN `endDate` DATE)   BEGIN
    DECLARE isAvailable INT;

    SELECT COUNT(*) INTO isAvailable
    FROM Reservation
    WHERE room_id = roomNumber
        AND start_date <= endDate
        AND end_date >= startDate;

    IF isAvailable = 1 THEN
        SELECT CONCAT('Room ', roomNumber, ' is available for the specified date range.') AS availability;
    ELSE
        SELECT CONCAT('Room ', roomNumber, ' is not available for the specified date range.') AS availability;
    END IF;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `CalculateReservationTotalPrice` (`reservationId` INT) RETURNS DECIMAL(10,2)  BEGIN
    DECLARE totalPrice DECIMAL(10,2);

    -- Calculate the duration of stay in days
    SET @startDate = (SELECT start_date FROM Reservation WHERE id = reservationId);
    SET @endDate = (SELECT end_date FROM Reservation WHERE id = reservationId);
    SET @numDays = DATEDIFF(@endDate, @startDate) + 1;

    -- Get the room price for the reservation
    SET @roomId = (SELECT room_id FROM Reservation WHERE id = reservationId);
    SET @roomPrice = (SELECT price FROM Room WHERE id = @roomId);

    -- Calculate the total price
    SET totalPrice = @numDays * @roomPrice;

    -- Return the total price
    RETURN totalPrice;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`id`, `name`, `email`, `phone`) VALUES
(1, 'Abdul Malik', 'abdmalik@example.com', '1234567890'),
(2, 'Sam Smith', 'samsmith@example.com', '9876543210'),
(3, 'Michael Jackson', 'michaeljackson@example.com', '5555555555');

-- --------------------------------------------------------

--
-- Table structure for table `facilityreservation`
--

CREATE TABLE `facilityreservation` (
  `id` int(11) NOT NULL,
  `reservation_id` int(11) NOT NULL,
  `facility_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `facilityreservation`
--

INSERT INTO `facilityreservation` (`id`, `reservation_id`, `facility_id`) VALUES
(1, 1, 3),
(2, 2, 1),
(3, 3, 3);

-- --------------------------------------------------------

--
-- Table structure for table `hotelfacility`
--

CREATE TABLE `hotelfacility` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hotelfacility`
--

INSERT INTO `hotelfacility` (`id`, `name`) VALUES
(1, 'Swimming Pool'),
(2, 'Gym'),
(3, 'Restaurant');

-- --------------------------------------------------------

--
-- Table structure for table `reservation`
--

CREATE TABLE `reservation` (
  `id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reservation`
--

INSERT INTO `reservation` (`id`, `customer_id`, `room_id`, `start_date`, `end_date`) VALUES
(1, 1, 1, '2023-06-21', '2023-06-22'),
(2, 2, 3, '2023-06-24', '2023-06-26'),
(3, 3, 2, '2023-06-27', '2023-06-30');

--
-- Triggers `reservation`
--
DELIMITER $$
CREATE TRIGGER `ProcessPayment` AFTER INSERT ON `reservation` FOR EACH ROW BEGIN
    DECLARE totalAmount DECIMAL(10, 2);
    
    -- hitung jumlah menginap
    SET totalAmount = (SELECT CalculateTotalPrice(NEW.room_id, NEW.start_date, NEW.end_date, 0.0));

    -- masukkan record baru kedalam tabel
    INSERT INTO Payment (reservation_id, amount, payment_date)
    VALUES (NEW.id, totalAmount, NOW());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `UpdateRoomAvailability` AFTER INSERT ON `reservation` FOR EACH ROW BEGIN
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
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reservationdetail`
--

CREATE TABLE `reservationdetail` (
  `id` int(11) NOT NULL,
  `facility_reservation_id` int(11) NOT NULL,
  `hotel_facility_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `reservationsbydate`
-- (See below for the actual view)
--
CREATE TABLE `reservationsbydate` (
`reservation_id` int(11)
,`start_date` date
,`end_date` date
,`customer_name` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `revenuereports`
-- (See below for the actual view)
--
CREATE TABLE `revenuereports` (
`reservation_id` int(11)
,`start_date` date
,`end_date` date
,`customer_name` varchar(255)
,`total_price` decimal(30,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `room`
--

CREATE TABLE `room` (
  `id` int(11) NOT NULL,
  `room_number` int(11) NOT NULL,
  `type` varchar(50) NOT NULL,
  `price` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `room`
--

INSERT INTO `room` (`id`, `room_number`, `type`, `price`) VALUES
(1, 101, 'Standard', 100.00),
(2, 202, 'Deluxe', 200.00),
(3, 303, 'VIP', 400.00);

-- --------------------------------------------------------

--
-- Stand-in structure for view `roomavailability`
-- (See below for the actual view)
--
CREATE TABLE `roomavailability` (
`room_number` int(11)
,`type` varchar(50)
,`price` decimal(8,2)
,`availability` varchar(13)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `totalrevenue`
-- (See below for the actual view)
--
CREATE TABLE `totalrevenue` (
`reservation_id` int(11)
,`customer_name` varchar(255)
,`start_date` date
,`end_date` date
,`room_price` decimal(8,2)
,`duration_of_stay` int(7)
,`total_revenue` decimal(14,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `transaksi`
--

CREATE TABLE `transaksi` (
  `id` int(11) NOT NULL,
  `reservation_id` int(11) NOT NULL,
  `facility_id` int(11) NOT NULL,
  `room_price` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transaksi`
--

INSERT INTO `transaksi` (`id`, `reservation_id`, `facility_id`, `room_price`) VALUES
(1, 1, 1, 100.00),
(2, 2, 2, 200.00),
(3, 3, 3, 400.00);

-- --------------------------------------------------------

--
-- Structure for view `reservationsbydate`
--
DROP TABLE IF EXISTS `reservationsbydate`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `reservationsbydate`  AS SELECT `r`.`id` AS `reservation_id`, `r`.`start_date` AS `start_date`, `r`.`end_date` AS `end_date`, `c`.`name` AS `customer_name` FROM (`reservation` `r` join `customer` `c` on(`r`.`customer_id` = `c`.`id`)) ORDER BY `r`.`start_date` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `revenuereports`
--
DROP TABLE IF EXISTS `revenuereports`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `revenuereports`  AS SELECT `r`.`id` AS `reservation_id`, `r`.`start_date` AS `start_date`, `r`.`end_date` AS `end_date`, `c`.`name` AS `customer_name`, sum(`t`.`room_price`) AS `total_price` FROM ((`reservation` `r` join `customer` `c` on(`r`.`customer_id` = `c`.`id`)) join `transaksi` `t` on(`r`.`id` = `t`.`reservation_id`)) GROUP BY `r`.`id`, `r`.`start_date`, `r`.`end_date`, `c`.`name` ORDER BY `r`.`start_date` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `roomavailability`
--
DROP TABLE IF EXISTS `roomavailability`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `roomavailability`  AS SELECT `r`.`room_number` AS `room_number`, `r`.`type` AS `type`, `r`.`price` AS `price`, CASE WHEN `r`.`id` in (select `reservation`.`room_id` from `reservation`) THEN 'Not Available' ELSE 'Available' END AS `availability` FROM `room` AS `r` ;

-- --------------------------------------------------------

--
-- Structure for view `totalrevenue`
--
DROP TABLE IF EXISTS `totalrevenue`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `totalrevenue`  AS SELECT `r`.`id` AS `reservation_id`, `c`.`name` AS `customer_name`, `r`.`start_date` AS `start_date`, `r`.`end_date` AS `end_date`, `t`.`room_price` AS `room_price`, to_days(`r`.`end_date`) - to_days(`r`.`start_date`) AS `duration_of_stay`, `t`.`room_price`* (to_days(`r`.`end_date`) - to_days(`r`.`start_date`)) AS `total_revenue` FROM ((`reservation` `r` join `customer` `c` on(`r`.`customer_id` = `c`.`id`)) join `transaksi` `t` on(`r`.`id` = `t`.`reservation_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `facilityreservation`
--
ALTER TABLE `facilityreservation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_reservation` (`reservation_id`),
  ADD KEY `fk_facility` (`facility_id`);

--
-- Indexes for table `hotelfacility`
--
ALTER TABLE `hotelfacility`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `reservation`
--
ALTER TABLE `reservation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_customer` (`customer_id`),
  ADD KEY `fk_room` (`room_id`);

--
-- Indexes for table `reservationdetail`
--
ALTER TABLE `reservationdetail`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_facility_reservation` (`facility_reservation_id`),
  ADD KEY `fk_hotel_facility` (`hotel_facility_id`);

--
-- Indexes for table `room`
--
ALTER TABLE `room`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_trans_reserv` (`reservation_id`),
  ADD KEY `fk_trans_facility` (`facility_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `customer`
--
ALTER TABLE `customer`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `facilityreservation`
--
ALTER TABLE `facilityreservation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `hotelfacility`
--
ALTER TABLE `hotelfacility`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `reservation`
--
ALTER TABLE `reservation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `reservationdetail`
--
ALTER TABLE `reservationdetail`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `room`
--
ALTER TABLE `room`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `facilityreservation`
--
ALTER TABLE `facilityreservation`
  ADD CONSTRAINT `fk_facility` FOREIGN KEY (`facility_id`) REFERENCES `hotelfacility` (`id`),
  ADD CONSTRAINT `fk_reservation` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`id`);

--
-- Constraints for table `reservation`
--
ALTER TABLE `reservation`
  ADD CONSTRAINT `fk_customer` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`),
  ADD CONSTRAINT `fk_room` FOREIGN KEY (`room_id`) REFERENCES `room` (`id`);

--
-- Constraints for table `reservationdetail`
--
ALTER TABLE `reservationdetail`
  ADD CONSTRAINT `fk_facility_reservation` FOREIGN KEY (`facility_reservation_id`) REFERENCES `facilityreservation` (`id`),
  ADD CONSTRAINT `fk_hotel_facility` FOREIGN KEY (`hotel_facility_id`) REFERENCES `hotelfacility` (`id`);

--
-- Constraints for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD CONSTRAINT `fk_trans_facility` FOREIGN KEY (`facility_id`) REFERENCES `hotelfacility` (`id`),
  ADD CONSTRAINT `fk_trans_reserv` FOREIGN KEY (`reservation_id`) REFERENCES `reservation` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

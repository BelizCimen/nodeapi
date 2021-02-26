/*Tablo olusturma*/
create table AIRLINE_COMPANY(
	Company_name varchar(20) NOT NULL,
	Total_number_of_airplanes int,
	PRIMARY KEY (Company_name)
);


create table AIRPLANE_COMPANY(
	Company_name varchar(20) NOT NULL,
	Produced_airplane_number int,
	PRIMARY KEY (Company_name)
);


create table AIRPLANE_TYPE(
	Type_name varchar(20) NOT NULL,
	Max_seats int,
	PRIMARY KEY (Type_name)
);


create table AIRPLANE(
	Airplane_id varchar(20) NOT NULL,
	Total_number_of_seats int,
	Type_name varchar(20),
	Company_name varchar(20),
	PRIMARY KEY (Airplane_id),
	FOREIGN KEY (Type_name) REFERENCES AIRPLANE_TYPE(Type_name),
	FOREIGN KEY (Company_name) REFERENCES AIRPLANE_COMPANY(Company_name)
);


create table AIRPORT(
	Airport_code varchar(20) NOT NULL,
	Name varchar(50),
	City varchar(20),
	State varchar(20),
	PRIMARY KEY (Airport_code)
);


create table CAN_LAND(
	Airport_code varchar(20) NOT NULL,
	Type_name varchar(20),
	PRIMARY KEY (Airport_code,Type_name),
	FOREIGN KEY (Airport_code) REFERENCES AIRPORT(Airport_code),
	FOREIGN KEY (Type_name) REFERENCES AIRPLANE_TYPE(Type_name)
);


create table CUSTOMER(
	Customer_number varchar(20) NOT NULL,
	Passport_number varchar(20) UNIQUE,
	Email varchar(50),
	Address varchar(100),
	Country varchar(20),
	Customer_phone varchar(20),
	First_name varchar(20),
	Last_name varchar(20),
	PRIMARY KEY (Customer_number)
);


create table FLIGHT(
	Flight_number varchar(20) NOT NULL,
	Airline_company_name varchar(20),
	Weekday varchar(20),
	PRIMARY KEY (Flight_number),
	FOREIGN KEY (Airline_company_name) REFERENCES AIRLINE_COMPANY(Company_name)
);


create table FLIGHT_LEG(
	Flight_number varchar(20) NOT NULL,
	Leg_number varchar(20) NOT NULL,
	Mile int NOT NULL,
	Arrival_airport_code varchar(20),
	Departure_airport_code varchar(20),
	PRIMARY KEY (Flight_number,Leg_number),
	FOREIGN KEY (Flight_number) REFERENCES FLIGHT(Flight_number),
	FOREIGN KEY (Arrival_airport_code) REFERENCES AIRPORT(Airport_code),
	FOREIGN KEY (Departure_airport_code) REFERENCES AIRPORT(Airport_code)
);


create table LEG_INSTANCE(
	Date date NOT NULL,
	Flight_number varchar(20) NOT NULL,
	Leg_number varchar(20) NOT NULL,
	Number_of_available_seats int,
	Airplane_id varchar(20),
	Arrival_airport_code varchar(20),
	Departure_airport_code varchar(20),
	PRIMARY KEY (Date,Flight_number,Leg_number),
	FOREIGN KEY (Flight_number,Leg_number) REFERENCES FLIGHT_LEG(Flight_number,Leg_number),
	FOREIGN KEY (Airplane_id) REFERENCES AIRPLANE(Airplane_id),
	FOREIGN KEY (Arrival_airport_code) REFERENCES AIRPORT(Airport_code),
	FOREIGN KEY (Departure_airport_code) REFERENCES AIRPORT(Airport_code)
);


create table FARES(
	Fare_code int NOT NULL,
	Flight_number varchar(20) NOT NULL,
	Amount decimal(8,2),
	Restriction bit,
	PRIMARY KEY (Fare_code,Flight_number),
	FOREIGN KEY (Flight_number) REFERENCES FLIGHT(Flight_number)
);


create table FFC(
	Ffc_id int NOT NULL IDENTITY(1,1),
	Customer_number varchar(20) NOT NULL,
	Customer_degree varchar(20),
	Rewards varchar(100),
	Mileage int,
	PRIMARY KEY (Ffc_id,Customer_number),
	FOREIGN KEY (Customer_number) REFERENCES CUSTOMER(Customer_number)
);


create table OPERATES_IN(
	Company_name varchar(20) NOT NULL,
	Airport_code varchar(20) NOT NULL,
	PRIMARY KEY (Company_name,Airport_code),
	FOREIGN KEY (Company_name) REFERENCES AIRLINE_COMPANY(Company_name),
	FOREIGN KEY (Airport_code) REFERENCES AIRPORT(Airport_code)
);


create table SEAT(
	Customer_number varchar(20) NOT NULL,
	Seat_number int NOT NULL,
	Seat_code varchar(1) NOT NULL,
	Flight_number varchar(20),
	Leg_number varchar(20),
	Date date,
	Fare_code int,
	CONSTRAINT Flight_seat_unique UNIQUE (Flight_number,Seat_number,Seat_code),
	PRIMARY KEY (Flight_number,Leg_number,Customer_number,Seat_number,Seat_code),
	FOREIGN KEY (Customer_number) REFERENCES CUSTOMER(Customer_number),
	FOREIGN KEY (Fare_code,Flight_number) REFERENCES FARES (Fare_code,Flight_number),
	FOREIGN KEY (Date,Flight_number,Leg_number) REFERENCES LEG_INSTANCE(Date,Flight_number,Leg_number)
);


/*Triggerlar*/-----------------------------------------------------------------------------------------



CREATE TRIGGER CreateFFC
   ON  CUSTOMER
   AFTER INSERT
AS 
BEGIN  
	INSERT INTO FFC (Customer_number)
		SELECT Customer_number FROM  INSERTED
END



CREATE TRIGGER UpdateMil
   ON  SEAT
   AFTER INSERT
AS 
BEGIN  
	
	Declare @mil int
	Declare @customer varchar(20)
	
	SELECT @mil = FL.Mile, @customer = I.Customer_number
	From FLIGHT_LEG AS FL, INSERTED AS I
	WHERE FL.Flight_number = I.Flight_number AND FL.Leg_number = I.Leg_number

	UPDATE FFC
	SET Mileage = ISNULL(Mileage, 0) + @mil
	WHERE Customer_number = @customer 

END
 

 
CREATE TRIGGER [dbo].[UpdateDegreeRewards]
   ON  [dbo].[FFC]
   AFTER INSERT, UPDATE
AS 
BEGIN  
	
	Declare @customer varchar(20)
	
	SELECT @customer = Customer_number
	From INSERTED 
	
	UPDATE FFC
	SET Customer_degree = 
		CASE 
		WHEN Mileage >= 500 THEN 'Platin'
		WHEN Mileage < 500  AND Mileage >= 300 THEN 'Gold'
		WHEN Mileage < 300 AND Mileage >= 100 THEN 'Silver'
		END
	WHERE Customer_number = @customer

	UPDATE FFC
	SET Rewards = 
		CASE 
		WHEN Customer_degree = 'Platin' THEN 'Round Trip'
		WHEN Customer_degree = 'Gold' THEN 'One Way Ticket'
		END
	WHERE Customer_number = @customer

END


 
CREATE TRIGGER UpdateAvailableSeat
   ON  SEAT
   AFTER INSERT
AS 
BEGIN  
	Declare @flightnumber varchar(20)
	Declare @legnumber varchar(20)
	Declare @date datetime

	SELECT @flightnumber = Flight_number, @legnumber = Leg_number, @date = Date
	From INSERTED
	 
	UPDATE LEG_INSTANCE
	SET Number_of_available_seats = Number_of_available_seats - 1
	WHERE Flight_number = @flightnumber AND Leg_number = @legnumber AND Date = @date

END



CREATE TRIGGER [dbo].[UpdateFareCode]
    ON [dbo].[SEAT]
    AFTER INSERT,UPDATE
AS
BEGIN
    UPDATE SEAT
    SET Fare_code =
        CASE
            WHEN I.Seat_number > 0 AND I.Seat_number <=5 THEN 3
            WHEN I.Seat_number > 5 AND I.Seat_number <=10 THEN 2
            WHEN I.Seat_number > 10 THEN 1
        END
    FROM SEAT, inserted AS I
    WHERE SEAT.Customer_number = I.Customer_number AND SEAT.Seat_number = I.Seat_number AND SEAT.Seat_code = I.Seat_code AND SEAT.Flight_number = I.Flight_number


END
GO

/*Check Constraintler*/-------------------------------------------------------------------------------


ALTER TABLE FLIGHT
ADD CONSTRAINT CHK_DAY CHECK (Weekday IN ('Sunday','Monday','Tuesday', 'Wednesday','Thursday','Friday','Saturday'));

ALTER TABLE FLIGHT_LEG
ADD CONSTRAINT CHK_AIRPORT_CODE CHECK (Arrival_airport_code <> Departure_airport_code);

ALTER TABLE LEG_INSTANCE
ADD CONSTRAINT CHK_DATE CHECK (Date >= getDate());

ALTER TABLE CUSTOMER
ADD CONSTRAINT CHK_EMAIL CHECK (Email LIKE '%@%');

ALTER TABLE LEG_INSTANCE
ADD CONSTRAINT CHK_AVA_SEAT_NUM CHECK (Number_of_available_seats>=0)


/*Insertler*/-------------------------------------------------------------------------------------------




insert into AIRLINE_COMPANY values ('Pegasus',214) 
insert into AIRLINE_COMPANY values ('Türk Hava Yolları',300) 
insert into AIRLINE_COMPANY values ('SunExpress',90) 
insert into AIRLINE_COMPANY values ('Emirates',500) 
insert into AIRLINE_COMPANY values ('OnurAir',85) 
insert into AIRLINE_COMPANY values ('AnadoluJet',100) 
insert into AIRLINE_COMPANY values ('Finnair',250) 
insert into AIRLINE_COMPANY values ('Atlas Global',150) 
insert into AIRLINE_COMPANY values ('Lufthansa',400) 
insert into AIRLINE_COMPANY values ('Ryanair',357) 
insert into AIRLINE_COMPANY values ('Iberia',120) 
insert into AIRLINE_COMPANY values ('Azerbaijan Airlines',80) 
 

 
insert into AIRPLANE_COMPANY values ('Airbus',1552) 
insert into AIRPLANE_COMPANY values ('Boeing',1652) 



insert into AIRPLANE_TYPE values ('Boeing 747-8',150) 
insert into AIRPLANE_TYPE values ('Boeing 767-300F',120) 
insert into AIRPLANE_TYPE values ('Airbus A220',170) 
insert into AIRPLANE_TYPE values ('Airbus A310',160)  


insert into AIRPLANE values ('TC-AAA',150,'Boeing 747-8','Boeing') 
insert into AIRPLANE values ('TC-AAB',120,'Boeing 767-300F','Boeing') 
insert into AIRPLANE values ('TC-AAC',160,'Airbus A310','Airbus') 
insert into AIRPLANE values ('TC-AAD',170,'Airbus A220','Airbus') 


insert into FLIGHT values ('PK 1634','Pegasus','Sunday') 
insert into FLIGHT values ('PK 3745','Türk Hava Yolları','Monday') 
insert into FLIGHT values ('PK 2876','SunExpress','Tuesday') 
insert into FLIGHT values ('PK 4198','Emirates','Wednesday') 
insert into FLIGHT values ('PK 9583','OnurAir','Thursday') 
insert into FLIGHT values ('PK 9576','AnadoluJet','Friday') 
insert into FLIGHT values ('PK 4284','Finnair','Saturday') 
insert into FLIGHT values ('PK 5387','Atlas Global','Sunday') 
insert into FLIGHT values ('PK 8374','Lufthansa','Monday') 
insert into FLIGHT values ('PK 4374','Ryanair','Tuesday') 
insert into FLIGHT values ('PK 3945','Iberia','Wednesday') 
insert into FLIGHT values ('PK 7461','Azerbaijan Airlines','Thursday') 


insert into AIRPORT values ('ESB','Ankara Esenboğa Havalimanı','Ankara','Akyurt') 
insert into AIRPORT values ('ADB','Adnan Menderes Havalimanı','İzmir','Gaziemir')
insert into AIRPORT values ('AYT','Antalya Havalimanı','Antalya','Muratpaşa') 
insert into AIRPORT values ('IST','İstanbul Havalimanı','İstanbul','Arnavutköy')
insert into AIRPORT values ('DNZ','Denizli Çardak Havalimanı','Denizli','Çardak') 
insert into AIRPORT values ('SZF','Samsun Çarşamba Havalimanı','Samsun','Çarşamba')


insert into CAN_LAND values('ADB','Airbus A220')
insert into CAN_LAND values('ADB','Airbus A310')
insert into CAN_LAND values('ADB','Boeing 747-8')
insert into CAN_LAND values('ADB','Boeing 767-300F')

insert into CAN_LAND values('AYT','Airbus A220')
insert into CAN_LAND values('AYT','Airbus A310')
insert into CAN_LAND values('AYT','Boeing 747-8')
insert into CAN_LAND values('AYT','Boeing 767-300F')

insert into CAN_LAND values('DNZ','Airbus A220')
insert into CAN_LAND values('DNZ','Airbus A310')
insert into CAN_LAND values('DNZ','Boeing 747-8')
insert into CAN_LAND values('DNZ','Boeing 767-300F')

insert into CAN_LAND values('ESB','Airbus A220')
insert into CAN_LAND values('ESB','Airbus A310')
insert into CAN_LAND values('ESB','Boeing 747-8')
insert into CAN_LAND values('ESB','Boeing 767-300F')

insert into CAN_LAND values('IST','Airbus A220')
insert into CAN_LAND values('IST','Airbus A310')
insert into CAN_LAND values('IST','Boeing 747-8')
insert into CAN_LAND values('IST','Boeing 767-300F')

insert into CAN_LAND values('SZF','Airbus A220')
insert into CAN_LAND values('SZF','Airbus A310')
insert into CAN_LAND values('SZF','Boeing 747-8')
insert into CAN_LAND values('SZF','Boeing 767-300F')



insert into FARES values(1,'PK 1634',189.90,1)
insert into FARES values(2,'PK 1634',289.90,0)
insert into FARES values(3,'PK 1634',355.90,0)
insert into FARES values(1,'PK 2876',234.55,1)
insert into FARES values(2,'PK 2876',554.65,1)
insert into FARES values(3,'PK 2876',794.55,0)
insert into FARES values(1,'PK 3745',324.76,1)
insert into FARES values(2,'PK 3745',584.96,0)
insert into FARES values(3,'PK 3745',650.99,0)
insert into FARES values(1,'PK 3945',199.90,0)
insert into FARES values(2,'PK 3945',299.90,0)
insert into FARES values(3,'PK 3945',399.90,0)
insert into FARES values(1,'PK 4198',389.90,1)
insert into FARES values(2,'PK 4198',459.90,0)
insert into FARES values(3,'PK 4198',500.00,0)
insert into FARES values(1,'PK 4284',455.65,0)
insert into FARES values(2,'PK 4284',750.95,0)
insert into FARES values(3,'PK 4284',855.65,0)
insert into FARES values(1,'PK 4374',559.90,1)
insert into FARES values(2,'PK 4374',680.00,0)
insert into FARES values(3,'PK 4374',859.00,0)
insert into FARES values(1,'PK 5387',264.55,1)
insert into FARES values(2,'PK 5387',404.95,0)
insert into FARES values(3,'PK 5387',688.00,0)
insert into FARES values(1,'PK 7461',389.90,0)
insert into FARES values(2,'PK 7461',469.90,0)
insert into FARES values(3,'PK 7461',750.00,0)
insert into FARES values(1,'PK 8374',455.65,1)
insert into FARES values(2,'PK 8374',555.65,1)
insert into FARES values(3,'PK 8374',655.65,1)
insert into FARES values(1,'PK 9576',359.90,1)
insert into FARES values(2,'PK 9576',659.90,1)
insert into FARES values(3,'PK 9576',859.90,1)
insert into FARES values(1,'PK 9583',580.55,0)
insert into FARES values(2,'PK 9583',750.55,0)
insert into FARES values(3,'PK 9583',1004.55,0)




insert into FLIGHT_LEG values('PK 1634','ADB-DNZ',100,'DNZ','ADB')
insert into FLIGHT_LEG values('PK 2876','ESB-SZF',120,'SZF','ESB')
insert into FLIGHT_LEG values('PK 3745','SZF-AYT',90,'AYT','SZF')
insert into FLIGHT_LEG values('PK 3945','IST-SZF',10,'SZF','IST')
insert into FLIGHT_LEG values('PK 4198','AYT-IST',60,'IST','AYT')
insert into FLIGHT_LEG values('PK 4284','DNZ-ESB',50,'ESB','DNZ')
insert into FLIGHT_LEG values('PK 4374','IST-AYT',20,'AYT','IST')
insert into FLIGHT_LEG values('PK 5387','SZF-DNZ',110,'DNZ','SZF')
insert into FLIGHT_LEG values('PK 7461','IST-ESB',90,'ESB','IST')
insert into FLIGHT_LEG values('PK 8374','ADB-IST',70,'IST','ADB')



insert into LEG_INSTANCE values('2021-12-13','PK 1634','ADB-DNZ',108,'TC-AAB','DNZ','ADB')
insert into LEG_INSTANCE values('2021-07-25','PK 2876','ESB-SZF',145,'TC-AAD','SZF','ESB')
insert into LEG_INSTANCE values('2021-06-09','PK 3745','SZF-AYT',145,'TC-AAD','AYT','SZF')
insert into LEG_INSTANCE values('2021-05-27','PK 3945','IST-SZF',139,'TC-AAA','SZF','IST')
insert into LEG_INSTANCE values('2021-05-11','PK 4198','AYT-IST',155,'TC-AAC','IST','AYT')
insert into LEG_INSTANCE values('2021-05-09','PK 4284','DNZ-ESB',72,'TC-AAB','ESB','DNZ')
insert into LEG_INSTANCE values('2021-04-29','PK 4374','IST-AYT',77,'TC-AAA','AYT','IST')
insert into LEG_INSTANCE values('2021-03-10','PK 5387','SZF-DNZ',56,'TC-AAB','DNZ','SZF')
insert into LEG_INSTANCE values('2021-03-09','PK 7461','IST-ESB',56,'TC-AAA','ESB','IST')
insert into LEG_INSTANCE values('2021-02-17','PK 8374','ADB-IST',83,'TC-AAD','IST','ADB')



insert into OPERATES_IN values('Pegasus','DNZ')
insert into OPERATES_IN values('SunExpress','SZF')
insert into OPERATES_IN values('Türk Hava Yolları','AYT')
insert into OPERATES_IN values('Iberia','SZF')
insert into OPERATES_IN values('Emirates','IST')
insert into OPERATES_IN values('Finnair','ESB')
insert into OPERATES_IN values('Ryanair','AYT')
insert into OPERATES_IN values('Atlas Global','DNZ')
insert into OPERATES_IN values('Azerbaijan Airlines','ESB')
insert into OPERATES_IN values('Lufthansa','IST')



INSERT INTO [dbo].[CUSTOMER] VALUES ( '2359FCE6', '8027929', 'asanova.ru@1969mail.ru', '1', 'Russia', '79265568924', 'IRINA', 'ASANOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '25F26950', '4063623', 'bad83@bk.ru', 'RUS  RU', 'Russia', '8917214964', 'ALEXEY', 'BALYCHEV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '25E30F58', 'C04437F76', 'gokhanyil@hotmail.com', '', '', '905465608271', 'GÖKHAN', 'BEY')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1A449714', '732286006', 'vjv2003@list.ru', 'RUSSIAN FEDERATION yaroslav teplovoy   RUSSIAN FEDERATION', 'Russia', '', 'IULIIA', 'PICHUGINA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '51E06FA7', '8588380', 'kilimanjarotur4@mail.ru', '', 'Russia', '79509942172', 'ELENA', 'FROLOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4C08D829', '3940549', 'olgamo83@gmail.com', 'BOLOTNIKOVKAYA 3-7-23 MOSCOW RU', 'Russia', '', 'OLGA', 'MOISEEVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '2F2D008D', '6956241', 'molod@aqvatour.ru', '', 'Russia', '79645622211', 'YULIA', 'RAGULINA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4121880E', 'ED2893706', 'justynamesjasz@o2.pl', 'ul. Zwycięstwa 173, 43-178 Ornontowice', 'Poland', '693866654', 'JUSTYNA', 'MESJASZ')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9084E0AC', 'EF9182805', 'tomaszkos.priv@gmail.com', 'KOBJELJCE   POLAND', 'Poland', '', 'ANTONINA', 'KOS')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '842AAE3D', '095352', 'komonicznik@gazeta.pl', 'POW 36/38, 90-123 LODZ', 'Poland', '696008705', 'IWONA', 'SZERESZEWSKA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3803B374', 'EM2020673', 'pseman@eranet.pl', 'NOWASOZ VL. KRASZEW SRCEGO 3  PL', 'Poland', '', 'URSZULA', 'SEMAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '55532345', 'EG6511773', 'anna_puluz@intenz.eu', '43-100 TYCHY UL. ARMII KRAJOWEJ 3/28', 'Poland', '691636302', 'LUKASZ', 'DUKA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0453DFED', '721279', 'robertbascik@wp.pl', 'GROTA ROWECKIEGO 47/75, 30-348 KRAKOW', 'Poland', '605745361', 'ROBERT', 'BASCIK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0B53DFED', '521797', 'KLAUDIAKB@POCZTA.FM', 'GROTA ROWECKIEGO 47/75, 30-348 KRAKOW', 'Poland', '605745361', 'KLAUDIA', 'BASCIK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '6D430917', 'ENİ528074', 'krzysztof.gawron@ipoczta.eu', 'X, 59-220 LEGNICA', 'Poland', '609301787', 'KRZYSZTOF', 'GAWRON')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '847F8A68', '0334154', 'krysnie1957@wp.pl', 'DLUGA 54, 80-831 GDANSK', 'Poland', '603533513', 'KRYSTYNA', 'NIEDZWIECKA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4BE7D05C', 'EG 2389789', 'renataklocek@o2.pl', '44-335 Jastrzebie-Zdroj ul. Wodeckiego 9/9', 'Poland', '', 'RENATA', 'KLOCEK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '118034F2', 'EG8152147', 'marco304@gmail.com', 'OPAWSKA 10', 'Poland', '697016109', 'ZOFIA', 'PRZYPADLO')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '6E104E24', 'EA9105016', 'adamex@onet.eu', 'JANA PAWLA II 13, 42-350 SIEDLAC', 'Poland', '605564074', 'ADAM', 'PARUZEL')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7BB28411', 'EBO398287', 'tenispiotrowski@gmail.com', 'MODRZEWSKIEGO 28', 'Poland', '601685126', 'MICHAL', 'PIOTROWSKI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9A8CAD6F', 'AM818031S', 'rarusz_pgry@gmail.com', '.', 'Poland', '', 'DARIUSZ', 'NOWAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '89867AB2', 'AU4503974', 'gluszek009@wp.pl', 'WITOLDA 11 81-532 GDYNIA', 'Poland', '508386031', 'BOZENA', 'GLUSZEK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '18CBDA83', 'EM2362180', 'alinagawlik@wp.pl', 'ELEKTRONOWA 8B/3', 'Poland', '514024495', 'ALINA', 'GAWLIK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0DB2AF7D', 'AV 9152499', 'biuro@wakacyjnyagent.pl', 'MAKOWA 22A, 63-400 OSTROW WIELKOPOLSKI', 'Poland', '693831141', 'PAWEL', 'BRYCHCY')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '11CBDA83', 'EM9362178', 'alinagawlik@wp.pl', 'ELEKTRONOWA 8B/3', 'Poland', '504857844', 'MARIUSZ', 'GAWLIK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '930E8FBB', 'AT9170934', 'sunremo@o2.pl', 'POLAND   POL', 'Poland', '', 'RAFAŁ', 'SKONIECZNY')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '52875C56', 'EH3350172', 'biuro@firotout.pl', 'Gornoslaska 49 44-270 Rybnik', 'Poland', '609519255', 'MIRELLA', 'JESZKA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1ED1DB46', 'AJ0053003', 'adtom2@wp.pl', 'UL.WIETSKA 65A RADLOW 63-440 RASZKOW   POLAND', 'Poland', '607581761', 'ADAM', 'TOMALAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '2ED1DB46', 'AU8112891', 'adtom2@wp.pl', 'UL.WIETSKA 65A RADLOW 63-440 RASZKOW   POLAND', 'Poland', '', 'JULIA', 'TOMALAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '36D1DB46', 'EF3339999', 'adtom2@wp.pl', 'UL.WIETSKA 65A RADLOW 63-440 RASZKOW   POLAND', 'Poland', '', 'HANNA', 'TOMALAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0D24A86A', '5825152', 'kontakt@integratour.pl', 'Katowice Zawiszy Czarnego', 'Poland', '503303915', 'KATARZYNA', 'LORENTZ')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '77E0F519', 'EH0614079', 'turkowiak_a@wp.pl', 'UL. SWIECIECZKOWSKA 11  LASOCIE PL', 'Poland', '', 'OLIWIA', 'TURKOWIAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '01492FD4', 'EF7554222', 'MAGDALENAGODLEWSKA@SEBEX.EU', 'POL  PL', 'Poland', '502162444', 'MAGDALENA', 'GODLEWSKA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '91FD9828', 'ES8545523', 'jacek.kosmalski@kwmediator.pl', 'GRYCZANAL 5P 220 LEGNICA LEGNICA PL', 'Poland', '60678965', 'JACEK', 'KOSMALSKI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '98FD9828', 'ES3544426', 'renata.kosmalska@icloud.com', 'GRYCZANAL 5P 220 LEGNICA LEGNICA PL', 'Poland', '606789865', 'RENATA', 'KOSMALSKA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4F643777', 'EN7088114', 'evbodzio@gmail.com', '-', 'Poland', '601551951', 'EWA', 'DOBOSZ')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '5632FFA9', 'EK7584817', 'kamjaca@gmail.com', 'GORKIEGO 2A/5, 44-113 GLIWICE', 'Poland', '693452447', 'JACEK', 'KAMINSKI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '96738E02', 'EB2442034', 'lumka85@wp.pl', 'ANDERSA 34, 44-370 PSZOW', 'Poland', '505859042', 'TOMASZ', 'POLOCZEK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '02CCB4A2', 'EA5438556', 'walek22@vp.pl', '32-500 CHRZANOW, SIENKIEWICZA 13/6', 'Poland', '666661910', 'MATEUSZ', 'WIECEK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '412A7C3C', '0000', 'agnese76j@interia.pl', '..., 00-000 ...', 'Poland', '508804110', 'AGNIESZKA', 'JODLOWSKA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1C8D0908', '5416436', 'nuniakelly@op.pl', 'WRĘBOWA 1A/9 44-270 RYBNIK', 'Poland', '505864006', 'WIESLAW', 'PIELORZ')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9A8A3BBC', '272978', 'jmaga@onet.pl', 'UL. XXX-LECIA PRL 46/9', 'Poland', '603266440', 'JAN', 'MAGA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '76A5D60F', 'AV0105306', 'ko_ania@poczta.fm', 'GDYNSKA 7, 05-400 OTWOCK', 'Poland', '601753576', 'ANNA', 'SZULC')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '8442DD35', 'R828H9878', 'marek.kosek@onet.pl', 'GORNICZA 17/12 43-225 WOLA', 'Poland', '668126410', 'MAREK', 'KOSEK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '005058FD', 'BZ0M03284', 'sobikjustyna@wp.pl', 'ul. Zlota 11 A 44-266 Swierklany', 'Poland', '505798930', 'JUSTYNA', 'SOBIK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '6CAFC6F7', 'EF3644536', 't_kaminski81@o2.pl', 'NAFTOWA 2A/30', 'Poland', '508144574', 'TOMASZ', 'KAMINSKI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9D1204C2', 'EA6938581', 'kordek78@tlen.pl', 'Bledowska 15, 42-400 Lazy', 'Poland', '509801170', 'KONRAD', 'CIESLAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '05D52158', 'ZY0A97234', 'mateusz.superson85@gmail.com', '..., 00-000 ...', 'Poland', '790383939', 'MATEUSZ', 'SUPERSON')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '76328EA5', 'ENİ813033', 'osrodekdorota@gmail.com', 'ZAKOSY 20, 80-140 GDANSK', 'Poland', '', 'ELZBIETA', 'TYRALA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '49F21E7F', 'AYS950455', 'jszz@wp.pl', 'ul. Jaworowa, 35-113 Rzeszów', 'Poland', '602315310', 'JACEK', 'SZAWICA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '43A423D4', 'EN5107219', 'tymeksoroko@gmail.com', 'CHOLONIEWSKIEGO 8/10, 85-127 BYDGOSZCZ', 'Poland', '', 'TYMOTEUSZ', 'SOROKO')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '044FC36F', '7994852', 'lukasz@ingresso.pl', 'SPOLDZIELCZA 60, 42-350 RZENISZOW', 'Poland', '665756054', 'LUKASZ', 'KULAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0B4FC36F', '6756957', 'cecylia.kulak@onet.pl', 'SPOLDZIELCZA 60, 42-350 RZENISZOW', 'Poland', '665756054', 'CECYLIA', 'KULAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '141C8776', 'AS7960060', 'michalurbanski19811@wp.pl', 'LOSIA 8, 80-175 GDANSK', 'Poland', '888489849', 'MICHAL', 'URBANSKI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1F733BA0', '3146560', 'aleksey.vborisov@gmail.com', '', 'Russia', '79851568717', 'TOMAS', 'BEGLETSOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4A5A9BF3', '717704181', 'andvolobuev@gmail.com', 'RU RUSYA RU', 'Russia', '79272701395', 'ANDREI', 'VOLOBUV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7643A106', '4836783', 'aryld@cb.sletat.ru', '', 'Russia', '', 'ALEKSANDRA', 'IZMESTEVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '71659E7F', '032875', 'boytysova_28@mail.ru', 'спб', 'Russia', '79992268139', 'ALEKSANDR', 'BOYCOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A18B6E53', '2421832', '7929@mail.ru', '', 'Russia', '79265967680', 'ANDREI', 'IGNATOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '06A14D79', '172003', '9397590@ah-travel.ru', '', 'Russia', '79616097218', 'ARTUR', 'PREOBRAZHENSKIY')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A481511A', '0469664', 'al-zhdanov@mail.ru', '', 'Russia', '', 'VICTORIA', 'ALESHINA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '148F8D9B', '5474021', 'bron@onlinetours.ru', '', 'Russia', '79260838518', 'MARIIA', 'BORISOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '33EADA0D', '4691600', '7788900@mail.ru', '', 'Russia', '79637788900', 'ARTEM', 'TSEPLYAEV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4C3AEC81', '287795', 'beryozkina.cristina@yandex.ru', '', 'Russia', '79651930054', 'LYUBOV', 'BEREZKINA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1EA4E36F', '1337645', '6385449@mail.ru', '', 'Russia', '74956385449', 'ALEXEY', 'MAXIMOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '810A45BD', '1731805', 'boroda1610@yandex.ru', '', 'Russia', '79031243101', 'VLADIMIR', 'FIRSOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '8A7630D0', '3276427', 'boroda1610@yandex.ru', '', 'Russia', '79031243101', 'MARIAT', 'ALIBEKOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A14A691A', '613614', 'as-trak@mail.ru', '', 'Russia', '79870614312', 'NATALYA', 'GALLYAMOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0BDA868B', '469649', 'aslvov001@gmail.com', '', 'Russia', '79672787820', 'ALEKSANDR', 'LVOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3794B391', '870602', 'aslvov001@gmail.com', '', 'Russia', '79672787821', 'INDIRA', 'LVOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4447C0BD', '9867349', 'anastasia.pererva@gmail.com', '', 'Russia', '79162064100', 'ANASTASIIA', 'SHCHERBININA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '47DEEB7F', '9771789', 'annadobrydneva@mail.ru', '', 'Russia', '', 'ANNA', 'DOBRYDNEVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9AB4BAAC', '9303337', 'anikina9797@mail.ru', '', 'Russia', '79678881088', 'SNEZHANA', 'ANIKINA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '37C814B3', '1646859', 'anikina9797@mail.ru', '', 'Russia', '79579803619', 'PAVEL', 'KULIKOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '8A8DF7A4', '812298', 'andergan85@mail.ru', '', 'Russia', '79153261174', 'ANDERZHANOVA', 'NIKOL')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9851DED7', '404392', 'akkerdoll@mail.ru', '', 'Russia', '79102656874', 'YULIYA', 'SEREGINA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '99556A9A', '1683111', 'bounti-tour@yandex.ru', '', 'Russia', '', 'TATIANA', 'CHERNOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1BD68996', '746590', 'bron@onlinetours.ru', '', 'Russia', '74997000304', 'IRINA', 'KRAMOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '94A5658B', '2288527', 'bron.druzya@mail.ru', '', 'Russia', '', 'ANASTASIIA', 'KOSTRIKOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '87C1DA91', '9031437', 'bron.druzya@mail.ru', '', 'Russia', '', 'VADIM', 'PINAEV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '576760AE', '5986487', 'bron.druzya@mail.ru', '', 'Russia', '', 'ROMAN', 'DOLZHEVSKII')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '04101AAD', '417807', 'borism7890@rambler.ru', '', 'Russia', '79999808972', 'VALERIYA', 'BORISENKO')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A0BC967E', '9261347', '1059198@mail.ru', '', 'Russia', '79998616487', 'NIKITA', 'PODKOLZIN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A4BC967E', '6012017', '1059165@mail.ru', '', 'Russia', '', 'POLINA', 'INDRIKOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1A319E8D', '2476291', 'annaabasheva@gmail.com', '', 'Russia', '79260948966', 'ANNA', 'OGURTSOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '197AA8E4', '5595695', 'bobneva@mail.ru', '', 'Russia', '79112894662', 'OLGA', 'TEREKHOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '15A44173', '371636', 'best_travels@bk.ru', '40 лет Октября, 44', 'Russia', '79995681586', 'MARINA', 'PETROVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '550CAB64', '684077', 'afrantishov@yandex.ru', 'Москва', 'Russia', '79032480333', 'ALEKSANDR', 'FRANTISHOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9E5D7A0C', '3189852', 'alex_tabakova@mail.ru', '', 'Russia', '79670642849', 'ALEKSANDRA', 'TABAKOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9111D305', '890971', 'alexey48@yandex.ru', 'СПб, пр.Ветеранов 160-117', 'Russia', '79117340277', 'ALEKSEY', 'ARKHIPOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1ADE46DA', '453541', 'bk@hot.tom.ru', 'г.Томск ул.Ново-Киевская 31 кв 3', 'Russia', '79234070020', 'TATYANA', 'KRAYUSHKINA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '75E86145', '3799423', 'bazanovam@gmail.com', '', 'Russia', '79685047182', 'OLESIA', 'BAZANOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0D713AB8', '1007953', 'artemkoshel@gmail.com', '', 'Russia', '79096252727', 'ARTEM', 'KOSHEL')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3DAB866D', '134268', 'alena-mazalova@mail.ru', 'ЕКАТЕРИНБУРГ', 'Russia', '79120419701', 'ANNA', 'BELOBORODOVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3659D918', '739989', '7105544@gmail.com', 'МОСКВА', 'Russia', '', 'LEV', 'PAVKIN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '6D140C41', '340129', '7105544@gmail.com', 'МО', 'Russia', '79037105544', 'NIKOLAY', 'STOLYARENKO')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1AC3D5C4', '6826217', 'basil@newmail.ru', '', 'Russia', '79122448037', 'VASILY', 'TUTYNIN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9B335ACA', '1566419', 'art-nadia@mail.ru', 'ekaterinburg', 'Russia', '79676360345', 'ALEKSEI', 'SHMOTEV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9ECACACA', '7754318', '250@6468822.ru', '', 'Russia', '79118356505', 'SERGEY', 'SHEVCHUK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '13BD5355', '358355', 'assadovaya21@gmail.com', '', 'Russia', '79021310512', 'ANNA', 'SADOVAYA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9BA099A5', '6140299', 'agent@falcore.com.ua', 'Odessa', 'Russia', '0662456663', 'VIKTOR', 'ABDULKHALIKOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A51BB548', '5985537', 'alex.letunovsky@gmail.com', '', 'Russia', '79263895055', 'ALEKSANDR', 'LETUNOVSKII')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '87BDD344', '7633591', 'altercorp@qip.ru', 'MOSCOW', 'Russia', '79629015336', 'VITALII', 'SHIBANOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '40CA96EC', '417716', '4emodan12@mail.ru', '', 'Russia', '79124621469', 'ELENA', 'KNYAZEVA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '8B6BB198', '296508', 'anpnik@sbor.net', '', 'Russia', '79046387918', 'ANDREY', 'TYAGUN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '986BB198', '110730', 'anpnik@sbor.net', '', 'Russia', '79045558597', 'ANNA', 'TYAGUN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '6FB74F49', '253757', '15nata1985@gmail.com', '', 'Russia', '79163483566', 'ARTEM', 'RYZHOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '5AAA5B4F', '626311', '15nata1985@gmail.com', '', 'Russia', '79163483566', 'MIKAIL', 'SHKALOV')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '15D10CEA', '2869407', 'anetta-tour@mail.ru', '', 'Russia', '89504108800', 'ASMIK', 'GULIKIAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '13CD6441', '370071182', '1ideatravel@gmail.com', '', 'Turkey', '380677497926', 'YEMLIHA', 'AYDOGAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '08A731D1', 'A10M02884', 'cagri_demirci@hotmail.cm', 'TUR ANTALYA TR', 'Turkey', '905305149779', 'CAGRI', 'DEMIRCI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '738467EE', 'AOIZ22537', 'nilsin@nilsinturizm.com', 'KIRSEHIR AKCAKENT TC', 'Turkey', '905544059037', 'AHMET', 'OZTURK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '898467EE', 'A28R27212', 'bocekpinar@gmail.com', 'KIRSEHIR AKCAKENT TC', 'Turkey', '05433563730', 'PINAR', 'OZTURK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7FAF7314', 'A02E47775', 'emrekodabag@gmail.com', 'KULHAN MAH. 17.SOK NO 13/6 MERKEZ KARAMAN TR', 'Turkey', '05424168949', 'SALIH', 'KODABAG')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3EB663AF', 'A07V26586', '365@tur312.com', '  ', 'Turkey', '905302855502', 'OMER', 'KURT')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '8FA415AD', '08795248', 'happyrest1207@gmail.com', '', 'Turkey', '380663281543', 'ASIM', 'CICEKSEVEN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3D46E0E6', 'A01K33847', 'osmanoyran@gmai.com', 'TEKKE MAH 112 SOK NO:8 PAMUKKALE DENIZLI TR', 'Turkey', '05058242787', 'OSMAN', 'OYRAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7F46E0E6', 'HG78877K9', 'egece20@gmail.com', 'TEKKE MAH 112 SOK NO:8 PAMUKKALE DENIZLI TR', 'Turkey', '05058242787', 'FATIMA', 'OYRAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '1B86EA99', '04550587', '767474@ukr.net', '', 'Turkey', '380663844254', 'FURKAN', 'SENGOZ')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '49F7FEEA', 'A24T59105', 'mehmet@mozzotravel.com.tr', '  ', 'Turkey', '905356119763', 'CIGDEM', 'ULKE')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '53F7FEEA', 'A24T60439', 'cigdemulke@yahoo.com', 'HAMIDIYE MAH PARK CAD. ORENKENT SITESI H BLOK D 3 BURSA TR', 'Turkey', '05356119763', 'CELAL', 'ULKE')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9F04D931', 'A02P30490', 'mehmet@mozzotravel.com.tr', '  ', 'Turkey', '905302637807', 'HIKMET', 'BIYIKLI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3D0ACBFC', 'AI6069873', 'sena.ozdemir@hotmail.com', 'TUR ANKARA TR', 'Turkey', '05075492305', 'SENA', 'TOKER')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7A3D9F7F', '84843', 'serhatsnturk@gmail.com', 'FATIH MAH. ERGENEKON CAD. NO:8 ELMADAG ANKARA TR', 'Turkey', '05071523337', 'SERHAT', 'SENTURK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '6E8B04DC', '23429498', '275.1@kiev.tui.ua', '', 'Turkey', '380931285522', 'MAHMUT', 'AKBULUT')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9ABB8C31', '15420378', 'galina.pustovoit@gmail.com', '', 'Turkey', '380930001925', 'IBRAHIM', 'DEMIRTAS')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '80D88BA9', 'A02S73291', 'serkancanbolat@yandex.com', 'CAYYOLU ANKARA TR', 'Turkey', '05061466630', 'SERKAN', 'CANBOLAT')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A0EBD384', 'A17Z58294', 'uysaln631@gmail.com', 'KECIOREN  ANKARA ', 'Turkey', '', 'BEHIYE', 'KELESER')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '5A496F10', '828737', 'aynurkus@gmx.net', 'KOLN KOLN DE', 'Turkey', '05356514361', 'AYNUR', 'INCE')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0B80C3FD', 'A06N17616', 'cigdemkose@gmail.com', 'ANKARA ANKARA TR', 'Turkey', '05354011420', 'CIGDEM', 'CEPE')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '03817DA5', 'AI6H85778', 'eryol27@hotmail.com', 'SEHITKAMIL  GAZIANTEP TR', 'Turkey', '05319187693', 'SEVGI', 'ERYOL')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '07817DA5', 'Aİ6H85952', 'eryol27@hotmail.com', 'SEHITKAMIL  GAZIANTEP TR', 'Turkey', '05319187693', 'TUNCAY', 'ERYOL')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '13817DA5', 'A02137701', 'mertarabaci@gmail.com', 'ILBANK MAH.GUNEYPARK 1R/87 ANKARA TR', 'Turkey', '0532627656', 'MERT', 'ARABACI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '17817DA5', 'Aİ7G20096', 'mertarabaci@gmail.com', 'ILKBAHAR MAH.GUNEYPARK 1R / 87  ANKARA TR', 'Turkey', '05326257656', 'NEVRA', 'ARABACI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A0BF89F6', 'A13U33196', 'rashalog61@hotmail.com', 'ATATURK MAH. SIRMABIYIKLAR SOK. NO:13 D:35 UNYE ORDU TR', 'Turkey', '05534761161', 'NESIBE', 'HALILOGLU')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '0FA19DE1', 'A26A01197', 'meltemmm_unal@hotmail.com', 'CANAKKALE CANAKKALE TR', 'Turkey', '', 'MELTEM', 'UCANER')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '888A3109', 'A21Y91648', 'mcosanoglu@sisecam.com', 'GUZELYALI MAH.8112 SOK.A BLOK K2/4 CUKUROVA ADANA TR', 'Turkey', '905334239766', 'MELIH', 'COSANOGLU')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3D07F89A', 'AI9M47472', 'eczenes23@gmail.com', 'KAYABASI MAH.75.YIL CADDESI AKIK SITESI C317 ISTANBUL TR', 'Turkey', '05330902323', 'ENES', 'SIK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9D8A9784', 'AI8Z69894', 'hanim_kaya@hotmail.com', 'ERTAS BULVARI NO 21/1 ESKISEHIR TR', 'Turkey', '905527050492', 'ERKAN', 'ERKART')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7C4E9163', '888589', 'ayseszgn@hotmail.com', 'UNCALI MAH 1251 SOK AQUALIFE EVLERI E BLOK K3 D7 ANTALYA TR', 'Turkey', '05324460729', 'AYSE', 'AKCAY')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4855CC69', '587898', 'elifyesim.filiz@gmail.com', 'CAGLAYAN MAH.  ANTALYA TR', 'Turkey', '05326038476', 'ELIF', 'FILIZ')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '5755CC69', '3071395', 'ekimdeniz1@hotmail.com', 'ISTANBUL KAGITHANE ANTALYA TR', 'Turkey', '05353694070', 'EKIM', 'AKARSLAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9E3AF758', 'A25J87438', 'cebaturizm@gmail.com', ' AYFONKARAHISAR TR', 'Turkey', '905377672174', 'UMIT', 'YIYIT')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7AD4B1B3', '1214', 'isleyen@yahoo.com', ' ISTANBUL TR', 'Turkey', '', 'KAAN', 'ISLEYEN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A3E47050', 'A13A77495', 'mahir.baskurkcu@alpfaint.com.tr', 'SEVGI MAH N SALIH ISGOREN CAD 71/2 GAZIEMIR IZMIR TR', 'Turkey', '05305515522', 'EMISE', 'BASKURKCU')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '750F74EB', 'A08C49003', 'murat.karakus@otis.com', 'ANKARA CANNKAYA TC', 'Turkey', '05050907375', 'MURAT', 'KARAKUS')
INSERT INTO [dbo].[CUSTOMER] VALUES ( 'A3ACA6C3', '486778', 'halitguezey58@gmail.com', 'ALM DAISBURG DE', 'Turkey', '0491744796489', 'HALIT', 'GUZEY')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4B050E33', 'A02J67059', 'berkay.kaplan@hotmail.com', 'GAZIANTEP NIZIP TC', 'Turkey', '', 'BEDIHA', 'KAPLAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '50FB4A9D', 'A27J14816', 'umitbum@gmail.com', 'GIRESUN DOGANKENT GIRESUN TC', 'Turkey', '05327879989', 'KUZEY', 'SAGBAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3BC1448C', 'A11U75912', 'bayramtugba29@gmail.com', 'TC ISTANBUL TR', 'Turkey', '05362917353', 'EMINE', 'BAYRAM')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '80BFBCE5', 'A04E13681', 'senocak84@hotmail.com', 'ORDU BELEDIYE OTOGARI NO:3 ALTINORDU ORDU TR', 'Turkey', '05419405152', 'BAGIS', 'SENOCAK')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '4C769CD8', 'A07F92794', 'dhakan58@outlook.com', 'ANTALYA  ', 'Turkey', '05340161670', 'HAKAN', 'DOGAN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '78EE6AFB', '322860', 'muratolgun@gmal.com', 'KONYA SELCUKLU TC', 'Turkey', '05326979388', 'MEHMET', 'OLGUN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3F57B893', 'A16C89306', 'banugulapoglu@hotmail.com', 'BASAKSEHIR ISTANBUL ISTANBUL TC', 'Turkey', '05369785560', 'BANU', 'GULAPOGLU')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '11D903A9', '4CJ 56218521', 'yasarozkarabekir@hotmal.com', 'KONYAALTI ANTALYA ANTALYA TC', 'Turkey', '05375154151', 'YASAR', 'OZKARABEKIR')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '15D903A9', 'A05I32409', 'sevgiozkarabekir@0hotmail.com', 'KONYAALTI ANTALYA MERKEZ ANTALYA TC', 'Turkey', '', 'SEVGI', 'OZKARABEKIR')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '09AAE44D', 'U13532304', 'cankapli.rche@gmal.com', 'ALSANCAK IZMIR  TC', 'Turkey', '05414672214', 'ALICAN', 'KAPLI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '3F7664B3', '352220', 'erkutsamanci@llve.com', 'GENCLIK MAH MURATPASA ANTALYA  TR', 'Turkey', '05326517645', 'ESMIRA', 'SAMANCI')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '5098F944', 'AI9145137', 'cerencetin142@hotmail.com', 'HAVZA MAH SIDDIK SOK 7/4  KONYA TR', 'Turkey', '05301157442', 'LEYLA', 'CETIN')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '7761C93A', 'A15H97632', 'ayseguuzunkayaa@gmal.com', 'SEKER MAH/ KENMER KONAKLARI 6/18 KONYA TR', 'Turkey', '05071581878', 'MUSTAFA', 'UZUNKAYA')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '37A35407', 'A22H09223', 'ecz_umut@hotmail.com', 'GUVENTEPE GAZIANTEP TR', 'Turkey', '05057271448', 'ARSLANOGLU', 'HAKVERDI')



insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6CAFC6F7',12,'A','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6FB74F49',11,'C','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6D140C41',7,'A','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6E104E24',9,'C','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6E8B04DC',9,'B','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6D430917',7,'C','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7761C93A',6,'C','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('77E0F519',5,'C','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('78EE6AFB',7,'B','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7A3D9F7F',5,'A','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7AD4B1B3',10,'B','PK 1634','ADB-DNZ','2021-12-13')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7BB28411',23,'C','PK 1634','ADB-DNZ','2021-12-13')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6CAFC6F7',24,'B','PK 2876','ESB-SZF','2021-07-25')


insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('71659E7F',2,'A','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('738467EE',2,'B','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('750F74EB',2,'C','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('75E86145',5,'A','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('76328EA5',11,'B','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7643A106',12,'C','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('76A5D60F',13,'A','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7C4E9163',9,'A','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7F46E0E6',9,'B','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('7FAF7314',9,'C','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('80BFBCE5',11,'A','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('80D88BA9',22,'B','PK 2876','ESB-SZF','2021-07-25')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('810A45BD',24,'A','PK 2876','ESB-SZF','2021-07-25')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6CAFC6F7',25,'A','PK 3745','SZF-AYT','2021-06-09')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('842AAE3D',2,'A','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('8442DD35',2,'B','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('847F8A68',3,'A','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('87BDD344',1,'A','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('87C1DA91',4,'A','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('888A3109',5,'B','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('898467EE',11,'C','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('89867AB2',12,'B','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('8A7630D0',10,'A','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('8A8DF7A4',9,'A','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('8B6BB198',9,'B','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('8FA415AD',21,'A','PK 3745','SZF-AYT','2021-06-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9084E0AC',25,'C','PK 3745','SZF-AYT','2021-06-09')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('6CAFC6F7',24,'A','PK 3945','IST-SZF','2021-05-27')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9111D305',1,'A','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('91FD9828',11,'A','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('930E8FBB',10,'A','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('94A5658B',9,'A','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('96738E02',2,'B','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9851DED7',11,'C','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('986BB198',10,'B','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('98FD9828',10,'C','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('99556A9A',11,'B','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9A8A3BBC',2,'A','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9A8CAD6F',5,'B','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9AB4BAAC',7,'A','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9ABB8C31',9,'C','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9B335ACA',6,'B','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9BA099A5',23,'A','PK 3945','IST-SZF','2021-05-27')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9D1204C2',23,'C','PK 3945','IST-SZF','2021-05-27')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9D8A9784',1,'C','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9E3AF758',2,'A','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9E5D7A0C',5,'A','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9ECACACA',7,'B','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9F04D931',4,'A','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A0BC967E',9,'B','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A0BF89F6',11,'A','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A0EBD384',3,'B','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A14A691A',12,'A','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A18B6E53',6,'B','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A3ACA6C3',8,'A','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A3E47050',9,'C','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A481511A',22,'C','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A4BC967E',23,'A','PK 4198','AYT-IST','2021-05-11')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('A51BB548',25,'A','PK 4198','AYT-IST','2021-05-11')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('005058FD',1,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('01492FD4',1,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('02CCB4A2',1,'C','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('03817DA5',2,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('04101AAD',2,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('044FC36F',2,'C','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0453DFED',6,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('05D52158',6,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('06A14D79',7,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('07817DA5',7,'C','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('08A731D1',12,'C','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('09AAE44D',13,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0B4FC36F',14,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0B53DFED',14,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0B80C3FD',16,'C','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0BDA868B',18,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0D24A86A',21,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0D713AB8',23,'C','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0DB2AF7D',21,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('0FA19DE1',23,'B','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('118034F2',23,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('11CBDA83',24,'A','PK 8374','ADB-IST','2021-02-17')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('11D903A9',24,'B','PK 8374','ADB-IST','2021-02-17')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('13817DA5',1,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('13BD5355',1,'C','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('13CD6441',2,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('141C8776',2,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('148F8D9B',6,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('15A44173',6,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('15D10CEA',7,'C','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('15D903A9',11,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('17817DA5',12,'C','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('18CBDA83',13,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('197AA8E4',14,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1A319E8D',15,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1A449714',16,'C','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1AC3D5C4',17,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1ADE46DA',19,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1B86EA99',19,'C','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1BD68996',20,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1C8D0908',22,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1EA4E36F',23,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1ED1DB46',23,'C','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('1F733BA0',25,'A','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('2359FCE6',25,'B','PK 7461','IST-ESB','2021-03-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('25E30F58',25,'C','PK 7461','IST-ESB','2021-03-09')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('25F26950',1,'A','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('2ED1DB46',1,'C','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('2F2D008D',2,'A','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('33EADA0D',2,'B','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3659D918',6,'A','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('36D1DB46',6,'B','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3794B391',7,'C','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('37A35407',11,'B','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('37C814B3',12,'C','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3803B374',13,'A','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3BC1448C',14,'B','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3D07F89A',15,'B','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3D0ACBFC',16,'C','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3D46E0E6',17,'A','PK 5387','SZF-DNZ','2021-03-10')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3DAB866D',19,'B','PK 5387','SZF-DNZ','2021-03-10')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4C08D829',21,'B','PK 5387','SZF-DNZ','2021-03-10')


insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3EB663AF',1,'C','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3F57B893',2,'A','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('3F7664B3',2,'B','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('40CA96EC',3,'A','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4121880E',3,'C','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('412A7C3C',5,'A','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('43A423D4',5,'B','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4447C0BD',5,'C','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('47DEEB7F',7,'A','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4855CC69',10,'B','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('49F21E7F',13,'B','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('49F7FEEA',16,'C','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4A5A9BF3',19,'A','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4B050E33',19,'B','PK 4374','IST-AYT','2021-04-29')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4BE7D05C',20,'C','PK 4374','IST-AYT','2021-04-29')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4C08D829',22,'A','PK 4374','IST-AYT','2021-04-29')

insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4C3AEC81',1,'A','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4C769CD8',2,'B','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4F643777',2,'C','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('5098F944',4,'A','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('50FB4A9D',4,'C','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('51E06FA7',6,'A','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('52875C56',6,'B','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('53F7FEEA',6,'C','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('550CAB64',8,'B','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('55532345',11,'A','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('5632FFA9',13,'C','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('5755CC69',15,'B','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('576760AE',20,'A','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4B050E33',21,'B','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('5A496F10',22,'A','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('4C08D829',24,'A','PK 4284','DNZ-ESB','2021-05-09')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('47DEEB7F',25,'A','PK 4284','DNZ-ESB','2021-05-09')

--INSERT-------------------------------------------------------------------------------------------------------------------
insert into AIRLINE_COMPANY values ('AirFrance',214) 
insert into AIRPLANE_COMPANY values ('Embraer',1352) 
insert into AIRPLANE_TYPE values ('Embraer E012',160)
insert into AIRPLANE_TYPE values ('Boeing 000-1',200)
insert into AIRPLANE_TYPE values ('Boeing 000-2',200)
insert into AIRPLANE values ('TC-BLZ',140,'Embraer E012','Embraer') 
insert into AIRPLANE values ('TC-XYZ',140,'Boeing 000-2','Boeing ') 
insert into FLIGHT values ('PK 9987','AirFrance','Sunday') 
insert into FLIGHT values ('PK 1234','Pegasus','Wednesday') 
insert into AIRPORT values ('DLM','Dalaman Havalimanı','Muğla','Dalaman') 
insert into CAN_LAND values('DLM','Embraer E012')
insert into FARES values(1,'PK 9987',376.90,1)
insert into FLIGHT_LEG values('PK 9987','DLM-ADB',100,'ADB','DLM')
insert into LEG_INSTANCE values('2021-04-07','PK 9987','DLM-ADB',78,'TC-BLZ','ADB','DLM')
insert into OPERATES_IN values('AirFrance','ADB')
INSERT INTO [dbo].[CUSTOMER] VALUES ( '9879EZA4', 'XV27723', 'beliz.cimen@hotmail.com', '1', 'Turkey', '05555555555', 'BELIZ', 'SEVINC')
insert into SEAT(Customer_number,Seat_number,Seat_code,Flight_number,Leg_number,Date) values('9879EZA4',20,'B','PK 9987','DLM-ADB','2021-04-07')
--UPDATE----------------------------------------------------------------------------------------------------------------------------------------

UPDATE CUSTOMER SET First_name='BELIZ CIMEN' WHERE  Customer_number='9879EZA4'
UPDATE SEAT SET Seat_code='C' WHERE  Customer_number='9879EZA4'
UPDATE LEG_INSTANCE SET Number_of_available_seats='38' WHERE  Airplane_id='TC-BLZ'
UPDATE FLIGHT_LEG SET Departure_airport_code='AYT' WHERE  Flight_number='PK 9987'
UPDATE FARES SET Amount=400.90 WHERE  Flight_number='PK 9987'
UPDATE CAN_LAND SET Type_name='Boeing 747-8' WHERE  Type_name ='Embraer E012'
UPDATE AIRPORT
SET City = 'Muğla', State = NULL
WHERE Airport_code='DLM'
UPDATE FLIGHT SET Weekday='Monday' WHERE  Flight_number='PK 9987'
UPDATE AIRPLANE SET Type_name='Boeing 747-8',Company_name='Boeing' WHERE Airplane_id='TC-BLZ'
UPDATE AIRPLANE_TYPE SET Max_seats=132 WHERE  Type_name ='Embraer E012'
UPDATE AIRPLANE_COMPANY SET Produced_airplane_number=1660 WHERE Company_name='Embraer'
UPDATE AIRLINE_COMPANY SET Total_number_of_airplanes=300 WHERE Company_name='AirFrance'

--DELETE--------------------------------------------------------------------------------------------------------------------------------
DELETE FROM FFC WHERE Customer_number='9879EZA4'
DELETE FROM SEAT WHERE Customer_number='9879EZA4'
DELETE FROM CUSTOMER WHERE Customer_number='9879EZA4'
DELETE FROM SEAT WHERE Flight_number='PK 9987'
DELETE FROM LEG_INSTANCE WHERE Flight_number='PK 9987'
DELETE FROM FLIGHT_LEG WHERE Flight_number='PK 9987'
DELETE FROM FARES WHERE Flight_number='PK 9987'
DELETE FROM FLIGHT WHERE Flight_number='PK 9987'
DELETE FROM OPERATES_IN WHERE  Company_name='AirFrance'
DELETE FROM AIRLINE_COMPANY WHERE  Company_name='AirFrance'
DELETE FROM AIRPLANE_COMPANY WHERE  Company_name='Embraer'
DELETE FROM AIRPLANE_TYPE WHERE  Type_name='Embraer E012'
DELETE FROM AIRPLANE WHERE Airplane_id='TC-BLZ'
DELETE FROM CAN_LAND WHERE Airport_code='DLM'
DELETE FROM AIRPORT WHERE Airport_code='DLM'



/*Selectler*/--------------------------------------------------------------------------------------------------------------------------------

SELECT First_name,Last_name,CUSTOMER.Customer_number,Email,Customer_phone,Customer_degree,Rewards FROM CUSTOMER,FFC
	WHERE CUSTOMER.Customer_number=FFC.Customer_number

SELECT Date,City,Flight_number,Leg_Number FROM LEG_INSTANCE,AIRPORT
	WHERE Departure_airport_code=Airport_code
	ORDER BY City

SELECT Type_name,Departure_airport_code,Arrival_airport_code FROM AIRPLANE,LEG_INSTANCE
	WHERE AIRPLANE.Airplane_id=LEG_INSTANCE.Airplane_id
	

SELECT First_name,Last_name,Customer.Customer_number,SEAT.Flight_number,Seat_number,Seat_code,Amount FROM CUSTOMER,FARES,SEAT
	WHERE CUSTOMER.Customer_number=SEAT.Customer_number AND SEAT.Fare_code=FARES.Fare_code AND SEAT.Flight_number=Fares.Flight_number
	ORDER BY SEAT.Flight_number

SELECT City,Name,Airplane_id FROM AIRPORT,CAN_LAND,AIRPLANE
	WHERE AIRPORT.Airport_code=CAN_LAND.Airport_code AND CAN_LAND.Type_name=AIRPLANE.Type_name

SELECT Total_number_of_airplanes,Name,City FROM AIRLINE_COMPANY,OPERATES_IN,AIRPORT
	WHERE AIRLINE_COMPANY.Company_name=OPERATES_IN.Company_name AND OPERATES_IN.Airport_code=AIRPORT.Airport_code

SELECT First_Name,Last_name,max(Date) AS [Last flight] ,max(Mileage) AS Mileage FROM CUSTOMER,SEAT,FFC
	WHERE CUSTOMER.Customer_number=SEAT.Customer_number AND CUSTOMER.Customer_number=FFC.Customer_number
	GROUP BY First_name,Last_name

SELECT D.City AS Departure,A.City AS Arrival,Flight_number,Mile FROM FLIGHT_LEG,AIRPORT AS D,AIRPORT AS A
	WHERE FLIGHT_LEG.Departure_airport_code=D.Airport_code AND FLIGHT_LEG.Arrival_airport_code=A.Airport_code

SELECT Date,Weekday,Leg_INSTANCE.Flight_number,Leg_number,Airline_company_name,D.Name AS Departure,A.Name AS Arrival FROM LEG_INSTANCE,FLIGHT,AIRPORT AS D,AIRPORT AS A
	WHERE LEG_INSTANCE.Flight_number=FLIGHT.Flight_number AND LEG_INSTANCE.Departure_airport_code=D.Airport_code AND LEG_INSTANCE.Arrival_airport_code=A.Airport_code

SELECT First_name,Last_name,CUSTOMER.Customer_number,Customer_degree,Rewards,SEAT.Flight_number,Seat_number,Seat_code,Airplane_id FROM CUSTOMER,FFC,SEAT,LEG_INSTANCE
	WHERE CUSTOMER.Customer_number=SEAT.Customer_number AND CUSTOMER.Customer_number=FFC.Customer_number AND SEAT.Flight_number=LEG_INSTANCE.Flight_number
	ORDER BY First_name,Last_name

SELECT Date,Weekday,AIRLINE_COMPANY.Company_name,Mile FROM LEG_INSTANCE,AIRLINE_COMPANY,FLIGHT_LEG,FLIGHT
	WHERE AIRLINE_COMPANY.Company_name=FLIGHT.Airline_company_name AND FLIGHT.Flight_number=FLIGHT_LEG.Flight_number AND FLIGHT_LEG.Leg_number=LEG_INSTANCE.Leg_number

--EXIST/NOT EXIST--------------------------------------------------------------------------------------------------------------------------------------------
SELECT CUSTOMER.Customer_number,First_name,Last_name FROM CUSTOMER
WHERE EXISTS(SELECT * FROM FFC WHERE Customer_degree='Silver' AND CUSTOMER.Customer_number=FFC.Customer_number)

SELECT Type_name FROM AIRPLANE_TYPE
WHERE NOT EXISTS(SELECT * FROM AIRPLANE WHERE Type_name=AIRPLANE_TYPE.Type_name)

--NESTED QUERY------------------------------------------------------------------------------------

SELECT First_name,Last_name 
,(SELECT TOP 1 Date FROM SEAT WHERE CUSTOMER.Customer_number=SEAT.Customer_number ORDER BY Date DESC) AS Last_Flight,
 (SELECT TOP 1 Date FROM SEAT WHERE CUSTOMER.Customer_number=SEAT.Customer_number ORDER BY Date ) AS First_Flight
FROM CUSTOMER

SELECT Company_name,Type_name
,(SELECT TOP 1 Date FROM LEG_INSTANCE WHERE LEG_INSTANCE.Airplane_id=AIRPLANE.Airplane_id ORDER BY Date DESC) AS Last_Flight,
 (SELECT TOP 1 Date FROM LEG_INSTANCE WHERE LEG_INSTANCE.Airplane_id=AIRPLANE.Airplane_id ORDER BY Date ) AS First_Flight
FROM AIRPLANE

SELECT CUSTOMER.Customer_number,First_name,Last_name,Mileage
,(SELECT TOP 1 Mile FROM SEAT,FLIGHT_LEG WHERE CUSTOMER.Customer_number=SEAT.Customer_number AND FLIGHT_LEG.Flight_number=SEAT.Flight_number ORDER BY Date DESC) AS Last_Flights_Mile
FROM CUSTOMER,FFC
WHERE CUSTOMER.Customer_number=FFC.Customer_number

SELECT * FROM FLIGHT_LEG WHERE Arrival_airport_code IN
(SELECT Airport_code FROM AIRPORT WHERE City='İstanbul')

---JOIN CONDITIONS-------------------------------------------------------------------------------------------

SELECT FLIGHT.Flight_number,Leg_number,Date
FROM FLIGHT
LEFT JOIN SEAT on FLIGHT.Flight_number=SEAT.Flight_number

SELECT LEG_INSTANCE.*,AIRPLANE.Airplane_id
FROM LEG_INSTANCE
RIGHT JOIN AIRPLANE on LEG_INSTANCE.Airplane_id=AIRPLANE.Airplane_id

SELECT *
FROM AIRPLANE_TYPE
FULL OUTER JOIN AIRPLANE on  AIRPLANE_TYPE.Type_name=AIRPLANE.Type_name

---VIEWS---------------------------------------------------------------------------------------------------------

CREATE VIEW FLIGHT_LEG_DETAILS AS
SELECT FLIGHT_LEG.*, ARR.Name AS ArrivalAirportName, DEP.Name AS DepartureAirportName, ARR.City AS ArrivalCity, DEP.City AS DepartureCity 
FROM FLIGHT_LEG , AIRPORT AS ARR, AIRPORT AS DEP 
WHERE Arrival_airport_code = ARR.Airport_code AND Departure_airport_code = DEP.Airport_code

CREATE VIEW CUSTOMER_FLIGHT_DETAILS AS 
SELECT SEAT.*,First_name,Last_name,ARR.Name AS ArrivalAirportName, DEP.Name AS DepartureAirportName, ARR.City AS ArrivalCity, DEP.City AS DepartureCity
FROM SEAT,FLIGHT_LEG,AIRPORT AS ARR, AIRPORT AS DEP,CUSTOMER
WHERE Arrival_airport_code = ARR.Airport_code AND Departure_airport_code = DEP.Airport_code AND CUSTOMER.Customer_number=SEAT.Customer_number AND SEAT.Flight_number=FLIGHT_LEG.Flight_number AND SEAT.Leg_number=FLIGHT_LEG.Leg_number

CREATE VIEW CUSTOMER_PRİCE_DETAILS AS
SELECT CUSTOMER.Customer_number,First_name,Last_name,SEAT.Flight_number,Amount
FROM CUSTOMER,SEAT,FARES
WHERE Customer.Customer_number=SEAT.Customer_number AND SEAT.Flight_number=FARES.Flight_number AND SEAT.Fare_code=FARES.Fare_code

SELECT * FROM CUSTOMER_PRİCE_DETAILS

CREATE VIEW LAND_DETAILS AS  
SELECT CAN_LAND.Airport_code, AIRPORT.Name, CAN_LAND.Type_name, AIRPLANE.Airplane_id, AIRPLANE.Company_name FROM CAN_LAND, AIRPORT, AIRPLANE
  WHERE CAN_LAND.Airport_code = AIRPORT.Airport_code
  AND CAN_LAND.Type_name = AIRPLANE.Type_name

CREATE VIEW AIRPLANE_DETAILS AS
SELECT Airline_company_name,LEG_INSTANCE.Flight_number,AIRPLANE.Airplane_id
FROM FLIGHT,LEG_INSTANCE,AIRPLANE
WHERE LEG_INSTANCE.Flight_number=FLIGHT.Flight_number AND LEG_INSTANCE.Airplane_id=AIRPLANE.Airplane_id

SELECT * FROM AIRPLANE_DETAILS
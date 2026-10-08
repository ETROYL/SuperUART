

from time import sleep
import serial


FPGA = serial.Serial('/dev/ttyUSB3', 9600)  #define your serial port and baudrate
FPGA.timeout = 1
FPGA.isOpen()
	# print("Port not open.")
	# exit()

def init():
	# send pattern for SUART baud rate detection
	FPGA.write(b'\x55')
	sleep(0.1)

def reset():
	#Set the command##
	FPGA.write(b'\x76')
	FPGA.write(b'\xB1')
	FPGA.write(b'\x9D')
	FPGA.write(b'\x08')
	sleep(0.1)

def iic_write(slave_add, reg_add, val):
	#Set the command##
	FPGA.write(b'\xA5')
	FPGA.write(b'\xB5')
	FPGA.write(b'\xC5')
	FPGA.write(b'\xD5')
	###########################################
	if type(slave_add) == type(0x25):
		FPGA.write(bytes([slave_add]))  #slave address
	else:
		FPGA.write(bytes(slave_add))
	###########################################
	if type(reg_add) == type(0x25):
		FPGA.write(bytes([reg_add]))  #register address
	else:
		FPGA.write(bytes(reg_add))
	###########################################
	if type(val) == type(0x25):
		FPGA.write(bytes([val]))  #Register value to be writen
	else:
		FPGA.write(bytes(val))
	sleep(0.2)
	print(FPGA.read(FPGA.inWaiting()).hex())


def iic_read(slave_add, reg_add):
	#Set the command##
	FPGA.write(b'\xA0')
	FPGA.write(b'\xB0')
	FPGA.write(b'\xC0')
	FPGA.write(b'\xD0')
	###########################################
	if type(slave_add) == type(0x25):
		FPGA.write(bytes([slave_add]))  #slave address
	else:
		FPGA.write(bytes(slave_add))
	###########################################
	if type(reg_add) == type(0x25):
		FPGA.write(bytes([reg_add]))  #register address
	else:
		FPGA.write(bytes(reg_add))
	sleep(0.2)
	reg = FPGA.read(FPGA.inWaiting())
	print(reg)
	return reg


def and_mask(a, b):
	return bytes([a[0] & b[0]])

def or_mask(a, b):
	return bytes([a[0] | b[0]])


slave_add = 0xA2

init()

# for k in range(10):
# 	FPGA.write(b'\x00')
# 	FPGA.write(b'\x01')
# 	FPGA.write(b'\x02')
# 	FPGA.write(b'\x03')

# for k in range(10):
# 	FPGA.write(b'\x07')
# 	sleep(0.1)
# 	FPGA.write(b'\x08')
# 	sleep(0.1)
# iic_write(slave_add, 0x88, 0x88)
iic_read(slave_add, 10)
# reset()

FPGA.close()
exit()

# print("MS2_")
# iic_read(75)
# iic_read(76)
# iic_read(77)
# iic_read(78)
# iic_read(79)
# iic_read(80)
# iic_read(81)
# iic_read(82)
# iic_read(83)
# iic_read(84)
# print("MSN_")
# iic_read(97)
# iic_read(98)
# iic_read(99)
# iic_read(100)
# iic_read(101)
# iic_read(102)
# iic_read(103)
# iic_read(104)
# iic_read(105)
# iic_read(106)
# print("Rx")
# iic_read(31)
# iic_read(32)
# iic_read(33)
# iic_read(34)


iic_write(255, 0x00)
iic_write(230, 0x10)
iic_write(241, 0xE5)

print("R2")
iic_write(33, 0xc0)

print("write MS2_")
iic_write(75, 0x6A)
iic_write(76, 0x06)
iic_write(77, 0x18)
iic_write(78, 0x04)
iic_write(79, 0x00)
iic_write(80, 0x00)
iic_write(81, 0x29)
iic_write(82, 0x01)
iic_write(83, 0x00)
iic_write(84, 0x00)


iic_write(49, and_mask(iic_read(49), b'\x7F'))
iic_write(246, 0x02)
iic_write(241, 0x65)
sleep(0.1)

iic_write(45, iic_read(235))
iic_write(46, iic_read(236))

iic_write(47, or_mask(and_mask(iic_read(47), b'\xFC'), and_mask(iic_read(237), b'\x03')))
iic_write(49, or_mask(iic_read(49), b'\x80'))
iic_write(230, 0x00)

reset()


FPGA.close()
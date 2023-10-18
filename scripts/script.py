import numpy as np
import cv2
import math
import serial

#kernel size of the filter
KERNEL_SIZE = 3
#margin kept to avoid margin blackening
MARGIN = (KERNEL_SIZE-1)/2
#size of a block filtered at a time
BLOCK_SIZE = 5

#serial.Serial(NAME_OF_UART_PORT, BAUD_RATE, READ_TIME_OUT)
ser = serial.Serial('/dev/ttyUSB0',115200,timeout=0.050)

#read the image
img = cv2.imread(r"C:\Users\dtc\Desktop\opencv_test\noise_image.jpg",0)

#size of the image
R_I = img.shape[0]
C_I = img.shape[1]

#initiating the input image, output image and the final image
img_input = np.zeros((2*MARGIN+BLOCK_SIZE*math.ceil(R_I/BLOCK_SIZE), 2*MARGIN+BLOCK_SIZE*math.ceil(R_I/BLOCK_SIZE)),np.uint8)
img_output = np.zeros((2*MARGIN+BLOCK_SIZE*math.ceil(R_I/BLOCK_SIZE), 2*MARGIN+BLOCK_SIZE*math.ceil(R_I/BLOCK_SIZE)),np.uint8)
final_img = np.zeros((R_I,C_I))

#resizing the image
for r_i in range(R_I):
    for c_i in range(C_I):
        img_input[r_i+1][c_i+1] = img[r_i][c_i]

#no of blocks to be sent into the FPGA
r_blocks = int((img_input.shape[0]-2*MARGIN)/BLOCK_SIZE)
c_blocks = int((img_input.shape[1]-2*MARGIN)/BLOCK_SIZE)

#initiating the block to be sent to the FPGA
block_transfer = np.zeros((BLOCK_SIZE+MARGIN*2,BLOCK_SIZE+MARGIN*2),np.uint8)

for i in range(r_blocks):
    for j in range(c_blocks):
        for k in range(BLOCK_SIZE+MARGIN*2):
            for l in range(BLOCK_SIZE+MARGIN*2):
                #extracting the block
                block_transfer[k][l] = img_input[BLOCK_SIZE*i+k][BLOCK_SIZE*j+l]

        #flttening the block extracted
        block_transfer_flatten = block_transfer.flatten()
        #converting the binary
        block_transfer_bytes = block_transfer_flatten.tobytes()
        #sending inputs into FPGA via UART communication
        no_of_bytes_sent = ser.write(block_transfer_bytes)
        #receiving outputs from FPGA, 'No of cells' times each of 1 byte
        output_block_transfer_bytes = ser.read((BLOCK_SIZE+MARGIN*2)*(BLOCK_SIZE+MARGIN*2)*1)
        output_block_transfer = np.frombuffer(output_block_transfer_bytes, dtype=np.uint8)
        #reshaping the flat array into 2D matrix
        output_block_transfer = np.reshape(output_block_transfer,(BLOCK_SIZE+MARGIN*2,BLOCK_SIZE+MARGIN*2))

        #embed it into output image
        for m in range(BLOCK_SIZE+MARGIN*2):
            for n in range(BLOCK_SIZE+MARGIN*2):
                img_output[BLOCK_SIZE*i+m][BLOCK_SIZE*j+n] = output_block_transfer[m][n]
        
#triming the output image into final image
for i in range(R_I):
    for j in range(C_I):
        final_img[i][j] = output_block_transfer[i+1][j+1]

#generating the final image
cv2.imwrite(r"C:\Users\dtc\Desktop\opencv_test\filtered_image.jpg",final_img)



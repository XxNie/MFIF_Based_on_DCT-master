clear;clc 
close all
addpath(genpath('.\JPEGread'));

p=3;
block_size=8;
filtersize=3;

[imagename1, imagepath1]=uigetfile('./sourceimages/*.jpg;*.bmp;*.png;*.tif;*.tiff;*.pgm;*.gif','Please choose the first input image');
img1=imread(strcat(imagepath1,imagename1));    
[imagename2, imagepath2]=uigetfile('./sourceimages/*.jpg;*.bmp;*.png;*.tif;*.tiff;*.pgm;*.gif','Please choose the second input image');
img2=imread(strcat(imagepath2,imagename2));  

job1=jpeg_read(char(strcat(imagepath1,imagename1)));
job2=jpeg_read(char(strcat(imagepath2,imagename2)));
col1=job1.image_width;
row1=job1.image_height;

Y1=job1.coef_arrays{1};
Y2=job2.coef_arrays{1};
[row,col,d]=size(Y1);
padrow=(row-row1)/2;
padcol=(col-col1)/2;

quantDC=repmat(job1.quant_tables{1},[row/block_size,col/block_size,1]);
DC1=Y1.*quantDC;
DC2=Y2.*quantDC;

mat=zeros(block_size,block_size);
for i=1:block_size
    for j=1:block_size
        if (i+j<=p)
            mat(i,j)=1;
        end
    end
end

colDC1 = im2col(DC1,[block_size,block_size],'distinct');
colDC2 = im2col(DC2,[block_size,block_size],'distinct');
ncolDC1 = colDC1./repmat(sqrt(sum(colDC1.^2,1)),[block_size*block_size,1]);
ncolDC2 = colDC2./repmat(sqrt(sum(colDC2.^2,1)),[block_size*block_size,1]);
matx = im2col(mat,[block_size,block_size],'distinct');

timg1 = matx.*ncolDC1;
timg2 = matx.*ncolDC2;
f_im1 = (1- sum(timg1.^2,1)) ./ sum(timg1.^2,1);
f_im2 = (1- sum(timg2.^2,1)) ./ sum(timg2.^2,1);

dmap = zeros([row,col]);
dmap = (f_im1>f_im2);
dmap = reshape(dmap,row/block_size,col/block_size);

fi = ones(filtersize)/filtersize/filtersize;
dmap = imfilter(dmap, fi, 'symmetric');
dmap = imfilter(dmap, fi, 'symmetric');
dmap = reshape(dmap,1,size(dmap,1)*size(dmap,2));
dmap = repmat(dmap,[block_size*block_size,1]);
dmap = col2im(dmap,[block_size,block_size],[row,col],'distinct');
dmap = bwareaopen(dmap,3800);
dmap = bwareaopen(~dmap,3800);
dmap = ~dmap;
dmap = dmap(1+padrow:row-padrow,1+padcol:col-padcol,:);
%figure,imshow(dmap);

%%% finally fusion
fimg = uint8(dmap).*img1 + uint8(1-dmap).*img2;
%figure,imshow(fimg);
imwrite(fimg,'FusedImage.jpg');

       
function [FCNNFeature_c5, FCNNFeature_c4, FCNNFeature_c3, FCNNFeature_p2, FCNNFeature_c2, FCNNFeature_p1, FCNNFeature_c1]...
    = FlowCNNFeature(vid_name, use_gpu, NUM_HEIGHT, NUM_WIDTH, model_def_file, model_file, gpu_id)
L = 10;
% Input video
filelist =dir([vid_name,'*_x*.jpg']);
video = zeros(NUM_HEIGHT,NUM_WIDTH,L*2,length(filelist));
for i = 1: length(filelist)
    flow_x = imread(sprintf('%s_%04d.jpg',[vid_name,'flow_x'],i));
    flow_y = imread(sprintf('%s_%04d.jpg',[vid_name,'flow_y'],i));
    video(:,:,1,i) = imresize(flow_x,[NUM_HEIGHT,NUM_WIDTH],'bilinear');
    video(:,:,2,i) = imresize(flow_y,[NUM_HEIGHT,NUM_WIDTH],'bilinear');
end

for i = 1:L-1
    tmp = cat(4, video(:,:,(i-1)*2+1:i*2,2:end),video(:,:,(i-1)*2+1:i*2,end));
    video(:,:,i*2+1:i*2+2,:)  = tmp;
end


% Initialize ConvNet
if caffe('is_initialized') == 0
	if exist('use_gpu', 'var')
		matcaffe_init(use_gpu,model_def_file,model_file,gpu_id);
	else
		matcaffe_init();
	end
end


% Computing convolutional maps
d  = load('flow_mean');
FLOW_MEAN = d.image_mean;
FLOW_MEAN = imresize(FLOW_MEAN,[NUM_HEIGHT,NUM_WIDTH]);

batch_size = 40;
num_images = size(video,4);
num_batches = ceil(num_images/batch_size);
FCNNFeature_c5 = [];
FCNNFeature_c4 = [];
FCNNFeature_c3 = [];
FCNNFeature_p2 = [];
FCNNFeature_c2 = [];
FCNNFeature_p1 = [];
FCNNFeature_c1 = [];

for bb = 1 : num_batches
    range = 1 + batch_size*(bb-1): min(num_images,batch_size*bb);
    images = zeros(NUM_WIDTH, NUM_HEIGHT, L*2, batch_size, 'single');
    tmp = video(:,:,:,range);
	
	for ii = 1 : size(tmp,4)
		img = single(tmp(:,:,:,ii));
        images(:,:,:,ii) = permute(img -FLOW_MEAN,[2,1,3]);
	end
	
    caffe('forward',{images});
    feature_map = caffe('get_feature_maps');
    feature_c5 = permute(feature_map(14).feature_maps{1}, [2,1,3,4]);
    feature_c4 = permute(feature_map(12).feature_maps{1}, [2,1,3,4]);
    feature_c3 = permute(feature_map(10).feature_maps{1}, [2,1,3,4]);
    feature_p2 = permute(feature_map(8).feature_maps{1}, [2,1,3,4]);
%     feature_c2 = permute(feature_map(7).feature_maps{1}, [2,1,3,4]);
%     feature_p1 = permute(feature_map(4).feature_maps{1}, [2,1,3,4]);
%     feature_c1 = permute(feature_map(3).feature_maps{1}, [2,1,3,4]);
    if isempty(FCNNFeature_c5)
        FCNNFeature_c5 = zeros(size(feature_c5,1), size(feature_c5,2), size(feature_c5,3), num_images, 'single');
        FCNNFeature_c4 = zeros(size(feature_c4,1), size(feature_c4,2), size(feature_c4,3), num_images, 'single');
        FCNNFeature_c3 = zeros(size(feature_c3,1), size(feature_c3,2), size(feature_c3,3), num_images, 'single');
        FCNNFeature_p2 = zeros(size(feature_p2,1), size(feature_p2,2), size(feature_p2,3), num_images, 'single');
        % FCNNFeature_c2 = zeros(size(feature_c2,1), size(feature_c2,2), size(feature_c2,3), num_images, 'single');
        % FCNNFeature_p1 = zeros(size(feature_p1,1), size(feature_p1,2), size(feature_p1,3), num_images, 'single');
        % FCNNFeature_c1 = zeros(size(feature_c1,1), size(feature_c1,2), size(feature_c1,3), num_images, 'single');
    end
    FCNNFeature_c5(:,:,:,range) = feature_c5(:,:,:,mod(range-1,batch_size)+1);
    FCNNFeature_c4(:,:,:,range) = feature_c4(:,:,:,mod(range-1,batch_size)+1);
    FCNNFeature_c3(:,:,:,range) = feature_c3(:,:,:,mod(range-1,batch_size)+1);
    FCNNFeature_p2(:,:,:,range) = feature_p2(:,:,:,mod(range-1,batch_size)+1);
%     FCNNFeature_c2(:,:,:,range) = feature_c2(:,:,:,mod(range-1,batch_size)+1);
%     FCNNFeature_p1(:,:,:,range) = feature_p1(:,:,:,mod(range-1,batch_size)+1);
%     FCNNFeature_c1(:,:,:,range) = feature_c1(:,:,:,mod(range-1,batch_size)+1);
end

end
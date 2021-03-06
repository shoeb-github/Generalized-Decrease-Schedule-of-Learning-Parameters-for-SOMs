%%  Main driver
%   NML502-HW06-MohammedShoeb
function som_shoeb
%% HEADER
%HW06, main function. Simply calls driver functions for problem2b, problem3
%and problem4.
%INPUT
%   none.
%RETURN
%   none.
%%
    clear all;
    osuffix = fix(clock);
    fsuffix  = sprintf(repmat('_%d', 1, size(osuffix, 2)),osuffix );
    
    %run and collect results for problem2a
%     prob2a(fsuffix);
%     pause(2);
%     close all;
%    
%     % run and collect results for problem2b and problem 3
%     prob2b_and_3(fsuffix);
%     pause(2);
%     close all;
% 
%     %run and collect results for problem4
%     prob4(fsuffix); 

    % run and collect results for smartphone dataset
    probSmartPhone(fsuffix)
    
    display('Finished running all problems and saved figures/log reports.');
    pause(2);
    fclose('all');

end

%% Driver for problem 2a
function [W,total_iter] = prob2a(fsuffix)
%% HEADER
%HW06, Problem 2a: 2D Gaussian
%Function to setup the experiments and run SOM learn.
%INPUT
%   fsuffix: character string: file name suffix.
%RETURN
%   W : matrix: whose columns represnt the prototypes. The column indices
%       are equal to lattice node indices.
%   total_iter : scalar: Number of learning steps when training stopped.
%%  
%   setup parameters
    display('Starting problem 2a');
    [ST,~] = dbstack;
    this_function = ST.name;
    
    %generate data, pre-process data, setup parameeters
    npoints        = 1000;
    [X, D]         = generate_data_prob2a(npoints);
    nx             = size(X,2); % data dimensions, #data points
    lat_length     = 8;       % lattice length
    lat_width      = 8;       % lattice width
    M              = lat_length*lat_width;    % number of nodes in lattice.
    N              = 5e0;     % maximum learning epochs.    
    tol            = 1;       % classification error percentage tolerance.
    log_events     = 4e1;     % total instants to log network parameters.
    plotlog_step   = 1e1;     % plot logs after 10 calls to the logger.
    log_step       = floor(N*nx/log_events);
    mu_init        = 0.1;     % learning rate.
    mu_final       = 0.01;    % min. learning rate.
    rad_init       = floor(min([lat_length,lat_width])/2); % initial neighborhood.
    rad_final      = 1;       % min. allowed radius.
    T              = 4e3;     % 1 epoch time
    mu_decay_fn    = make_hyperbolic_decay(T); %1 epoch time constant
    rad_decay_fn   = make_hyperbolic_decay(T); %1 epoch time constant
    lattice        = make_rect_lattice(lat_width);%square lattice.
    learning_rate_schedule = make_schedule(mu_decay_fn, @(x)(x), ....
        mu_init,mu_final);
    radius_schedule = make_schedule(rad_decay_fn,@(x)(ceil(x-0.5)),...
        rad_init,rad_final);
    gaussian_neighborhood_function = ...
        make_gaussian_neighborhood_function(lattice, ...
        @(vi,vj)(sum(abs(vi-vj))), ...       
        radius_schedule);
    error_function = make_error_function();
    som_stop_predicate = make_stop_predicate(error_function,tol);
       
    %% create filenames/open output reporting files, figures
    ofile    = strcat(this_function,'out',fsuffix,'.txt');
    outfile  = fopen(ofile,'wt');
    fprintf('Performance characteristics will be printed in file: %s\n', ...
        ofile);
    fprintf(['Performance graphs will be plotted in files with ' ....
        'suffices: %s\n'],fsuffix);
    vw = [0,90];
    som_logger = make_logger(error_function,learning_rate_schedule, ...
        radius_schedule,outfile,N,nx,tol,plotlog_step, ...
        @(fig,W,tstr)(mesh2D_prototype_topology(fig,W,tstr,vw)),...
        'Problem2a, 2D Gaussian',strcat(this_function,'_',fsuffix));
    
    %% learn using som_learn
    [W,total_iter] = som_learn(X, M, gaussian_neighborhood_function, ... 
        learning_rate_schedule, N, som_stop_predicate, ...
        som_logger, log_step);
 
    %% process learned network, plot figures etc
    colmap = [0 0.251 0;0.251 0 0.502; 1 0.502 0.502; 0.502 0 0];
    function fig = mesh2D_prototype_topology(fig,W,tstr,vw)
        xyz = reshape(W',lat_length,lat_width,2);
        figure(fig);
        hold on;
        scatter3(X(1,:),X(2,:),0*X(1,:),0.5,'+','LineWidth',0.5,...
            'MarkerEdgeColor',[0.502 0.502 0.502]);        
        mesh(xyz(:,:,1),xyz(:,:,2),0*xyz(:,:,1),'LineStyle','-', ... 
            'LineWidth',2,'EdgeColor','black','Marker','o', ...
            'MarkerSize',3,'MarkerFaceColor','r','MarkerEdgeColor','r',...
            'FaceColor','none');
        grid on;
        view(vw);        
        title(tstr);
        hold off;  
    end

    function fig = scatter2D_data_points(fig,X,D,tstr,vw)
        figure(fig);
        hold on;
        colormap(colmap);
        scatter3(X(1,:),X(2,:),0*X(2,:),4,D-1,'+','LineWidth',1);
        view(vw)
        title(tstr);
        hold off;
    end

    fig = figure;
    fig = mesh2D_prototype_topology(fig,W,sprintf(['End of training, '...
        'total steps:%d'],total_iter),vw);
    fig = scatter2D_data_points(fig,X,D,sprintf(['End of training, '...
        'total steps:%d'],total_iter),vw);
    saveas(gcf,sprintf('%sfig%d_after_training_data_plot_%s.fig',...
        this_function,fig,fsuffix));

    fig = figure;
    whitebg([0 0 0]);
    tstr = 'Problem 2a, Fence and weights after training';
    fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr,2);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
    saveas(gcf,sprintf(['%sfig%d_after_training_mU_matrix_and_weights_'...
        '%s.fig'],this_function,fig,fsuffix));

    fig = figure;
    whitebg([0 0 0]);
    tstr = 'Problem 2a, Class colors and weights';
    colmapcell = {[0 0 0],[0 0.251 0],[0.251 0 0.502],[1 0.502 0.502],...
        [0.502 0 0]};
    fig = decorate_class_color(fig,lattice,W,X,D,colmapcell,tstr,0.1);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
    saveas(gcf,sprintf(['%sfig%d_after_training_classfication_'....
        'colors_and_weights_%s.fig'],this_function,fig,fsuffix));

    fig = figure;
    whitebg([0 0 0]);
    tstr = 'Problem 2a, Fence, class color map, and weights';
    fig = decorate_class_color(fig,lattice,W,X,D,colmapcell,tstr,2);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
    fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr,2);
    saveas(gcf,sprintf('%sfig%d_after_training_all_overlaid_', ...
        this_function,fig,fsuffix));

    whitebg('white');
    fprintf('Total learning steps: %d\n',total_iter);
    display('Finished problem 2a');
end

%% Driver for problem 2b
function [W,total_iter] = prob2b_and_3(fsuffix)
%% HEADER
%HW06, Problem 2b: 3D Gaussian and Problem 3 (plots).
%Function to setup the experiments and run SOM learn.
%INPUT
%   fsuffix: character string: file name suffix.
%RETURN
%   W : matrix: whose columns represnt the prototypes. The column indices
%       are equal to lattice node indices.
%   total_iter : scalar: Number of learning steps when training stopped.
%%  
%   setup parameters
    display('Starting problem 2b');
    [ST,~] = dbstack;
    this_function = ST.name;
    
    %generate data, pre-process data, setup parameeters
    npoints        = 1000;
    [X, D]         = generate_data_prob2b(npoints);
    nx             = size(X,2); % data dimensions, #data points
    lat_length     = 10;      % lattice length
    lat_width      = 10;      % lattice width
    M              = lat_length*lat_width;    % number of nodes in lattice.
    N              = 5e1;     % maximum learning epochs.    
    tol            = 1;       % classification error percentage tolerance.
    log_events     = 4e2;     % total instants to log network parameters.
    plotlog_step   = 1e1;     % plot logs after 10 calls to the logger.
    log_step       = floor(N*nx/log_events);
    mu_init        = 0.1;     % learning rate.
    mu_final       = 0.01;    % min. learning rate.
    rad_init       = floor(min([lat_length,lat_width])/2); % initial neighborhood.
    rad_final      = 1;       % min. allowed radius.
    T              = 4e3;     % 1 epoch time
    mu_decay_fn    = make_hyperbolic_decay(2*T); %2 epochs time constant. 
    rad_decay_fn   = make_hyperbolic_decay(2*T); %2 epochs time constant
    lattice        = make_rect_lattice(lat_width);%square lattice.
    learning_rate_schedule = make_schedule(mu_decay_fn, @(x)(x), ....
        mu_init,mu_final);
    radius_schedule = make_schedule(rad_decay_fn,@(x)(ceil(x-0.5)),...
        rad_init,rad_final);
    gaussian_neighborhood_function = ...
        make_gaussian_neighborhood_function(lattice, ...
        @(vi,vj)(sum(abs(vi-vj))), ...       
        radius_schedule);
    error_function = make_error_function();
    som_stop_predicate = make_stop_predicate(error_function,tol);
       
    %% create filenames/open output reporting files, figures
    ofile    = strcat(this_function,'out',fsuffix,'.txt');
    outfile  = fopen(ofile,'wt');
    fprintf('Performance characteristics will be printed in file: %s\n', ...
        ofile);
    fprintf(['Performance graphs will be plotted in files with ' ....
        'suffices: %s\n'],fsuffix);
    vw = [-60,40];
    som_logger = make_logger(error_function,learning_rate_schedule, ...
        radius_schedule,outfile,N,nx,tol,log_step,plotlog_step, ...
        @(fig,W,tstr)(mesh3D_prototype_topology(fig,W,tstr,vw)),...
        strcat(this_function,'_',fsuffix),'Problem2b, 3D Gaussian');
    
    %% learn using som_learn
    [W,total_iter] = som_learn(X, M, gaussian_neighborhood_function, ... 
        learning_rate_schedule, N, som_stop_predicate, ...
        som_logger, log_step);
 
    %% process learned network, plot figures etc
    function fig = mesh3D_prototype_topology(fig,W,tstr,vw)
        xyz = reshape(W',lat_length,lat_width,3);
        figure(fig);
        hold on;
        scatter3(X(1,:),X(2,:),X(3,:),0.5,'+','LineWidth',0.5,...
            'MarkerEdgeColor',[0.502 0.502 0.502]);
        mesh(xyz(:,:,1),xyz(:,:,2),xyz(:,:,3),'LineStyle','-', ... 
            'LineWidth',2,'EdgeColor','black','Marker','o', ...
            'MarkerSize',3,'MarkerFaceColor','r','MarkerEdgeColor','r',...
            'FaceColor','none');
        grid on;
        view(vw);        
        title(tstr);
        hold off;  
    end

    function fig = scatter3D_data_points(fig,X,D,tstr,vw)
        figure(fig);
        hold on;
        colmap = [0 0.251 0;0.251 0 0.502; 1 0.502 0.502; 0.502 0 0];
        colormap(colmap);
        scatter3(X(1,:),X(2,:),X(3,:),4,D-1,'+','LineWidth',1);
        view(vw)
        title(tstr);
        hold off;
    end

    fig = figure;
    fig = mesh3D_prototype_topology(fig,W,sprintf(['End of training, '...
        'total steps:%d'],total_iter),vw);
    fig = scatter3D_data_points(fig,X,D,sprintf(['End of training, '...
        'total steps:%d'],total_iter),vw);
    saveas(gcf,sprintf('%sfig%d_after_training_data_plot_%s.fig',...
        this_function,fig,fsuffix));

    fig = figure;
    whitebg('black');
    tstr = 'Problem 2b, Fence and weights after training';
    fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1]);
    saveas(gcf,sprintf(['%sfig%d_after_training_mU_matrix_and_weights_'...
        '%s.fig'],this_function,fig,fsuffix));

    fig = figure;
    tstr = 'Problem 2b, Class color and weights';
    colmapcell = {[0 0 0],[0 0.251 0],[0.251 0 0.502],[1 0.502 0.502],...
        [0.502 0 0]};
    fig = decorate_class_color(fig,lattice,W,X,D,colmapcell,tstr,0.1);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1]);
    saveas(gcf,sprintf(['%sfig%d_after_training_classfication_'....
        'colors_and_weights_%s.fig'],this_function,fig,fsuffix));

    fig = figure;
    tstr = 'Problem 2b, Fence, class color map, and weights';
    fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1]);
    fig = decorate_class_color(fig,lattice,W,X,D,colmapcell,tstr,5);
    saveas(gcf,sprintf('%sfig%d_after_training_all_overlaid_', ...
        this_function,fig,fsuffix));

    whitebg('white');
    fprintf('Total learning steps: %d\n',total_iter);    
    display('Finished problem 2b');
end

%% Driver for problem 4
function [W,total_iter] = prob4(fsuffix)
%% HEADER
%HW06, Problem 4: iris dataset
%Function to setup the experiments and run SOM learn.
%INPUT
%   fsuffix: character string: file name suffix.
%RETURN
%   W : matrix: whose columns represnt the prototypes. The column indices
%       are equal to lattice node indices.
%   total_iter : scalar: Number of learning steps when training stopped.
%%  
%   setup parameters
    display('Starting problem 4');
    [ST,~] = dbstack;
    this_function = ST.name;
    
    %generate data, pre-process data, setup parameeters
    [X, D]         = generate_data_prob4();
    nx             = size(X,2); % data dimensions, #data points
    lat_length     = 10;      % lattice length
    lat_width      = 10;      % lattice width
    M              = lat_length*lat_width;    % number of nodes in lattice.
    N              = 1e2;     % maximum learning epochs.    
    tol            = 1;       % classification error percentage tolerance.
    log_events     = 4e2;     % total instants to log network parameters.
    plotlog_step   = 20;      % plot logs after 20 calls to the logger.
    log_step       = floor(N*nx/log_events);
    mu_init        = 0.1;     % learning rate.
    mu_final       = 0.01;    % min. learning rate.
    rad_init       = floor(min([lat_length,lat_width])/2); % initial neighborhood.
    rad_final      = 1;       % min. allowed radius.
    T              = 150;     % 1 epoch time
    mu_decay_fn    = make_hyperbolic_decay(T); % 1 epoch time constant 
    rad_decay_fn   = make_hyperbolic_decay(T); % 1 epoch time constant
    lattice        = make_rect_lattice(lat_width);%square lattice.
    learning_rate_schedule = make_schedule(mu_decay_fn, @(x)(x), ....
        mu_init,mu_final);
    radius_schedule = make_schedule(rad_decay_fn,@round,rad_init,rad_final);
    gaussian_neighborhood_function = ...
        make_gaussian_neighborhood_function(lattice, ...
        @(vi,vj)(sum(abs(vi-vj))), ...       
        radius_schedule);
    error_function = make_error_function();
    som_stop_predicate = make_stop_predicate(error_function,tol);
       
    %% create filenames/open output reporting files, figures
    ofile    = strcat(this_function,'out',fsuffix,'.txt');
    outfile  = fopen(ofile,'wt');
    fprintf('Performance characteristics will be printed in file: %s\n', ...
        ofile);
    fprintf(['Performance graphs will be plotted in files with ' ....
        'suffices: %s\n'],fsuffix);
    
    label_color = {[0 0 0], [1 0 1], [0 1 1], [0 1 0]};
    label_text  = {'','SET','VER','VIR'};
    
    function fig = diag_plot(fig,W,tstr)
    % nested function. wrapper for plotting functions.
        fig = figure(fig);
        whitebg([0 0 0]);
        class_color = {[0 0 0], [0 0 0], [0 0 0], [0 0 0]};
        fig = decorate_class_color(fig,lattice,W,X,D,class_color,tstr,2);
        fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
        fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr,2);
        fig = decorate_class_label(fig,lattice,W,X,D,label_text,...
            label_color,4,tstr);
    end
    
    som_logger = make_logger(error_function,learning_rate_schedule,...
        radius_schedule,outfile,N,nx,tol,plotlog_step,...
        @diag_plot,'Problem4, iris dataset',...
        strcat(this_function,'_',fsuffix));
    
    %% learn using som_learn
    [W,total_iter] = som_learn(X, M, gaussian_neighborhood_function, ... 
        learning_rate_schedule, N, som_stop_predicate, ...
        som_logger, log_step);
    
    %% Process results after training.
    fig = figure;
    whitebg([0 0 0]);
    tstr = 'Problem 4, Fence, weights and labels after training';
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
    fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr,2);
    fig = decorate_class_label(fig,lattice,W,X,D,label_text,...
            label_color,4,tstr);
    saveas(gcf,sprintf(['%sfig%d_after_training_mU_matrix_and_weights_'...
        '%s.fig'],this_function,fig,fsuffix));

    fig = figure;
    tstr = 'Problem 4, Class color map, labels and weights after training';
    label_color = {[0 0 0], [1 1 1], [1 1 1], [1 1 1]};
    colmapcell  = {[0 0 0], [1 0 1], [0 1 1], [0 1 0]};
    fig = decorate_class_color(fig,lattice,W,X,D,colmapcell,tstr,0.1);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
    fig = decorate_class_label(fig,lattice,W,X,D,label_text,...
            label_color,5,tstr);
    saveas(gcf,sprintf(['%sfig%d_after_training_classfication_'....
        'mU_class_color_label_weights_%s.fig'],this_function,fig,fsuffix));

    fprintf('Total learning steps: %d\n',total_iter);
    display('Finished problem 4');
end

%% Driver for smartphone data
function [W,total_iter] = probSmartPhone(fsuffix)
%% HEADER
%Function to setup the experiments and run SOM learn.
%INPUT
%   fsuffix: character string: file name suffix.
%RETURN
%   W : matrix: whose columns represnt the prototypes. The column indices
%       are equal to lattice node indices.
%   total_iter : scalar: Number of learning steps when training stopped.
%%  
%   setup parameters
    display('Starting problem 4');
    [ST,~] = dbstack;
    this_function = ST.name;
    
    %generate data, pre-process data, setup parameeters
    data           = load('../dataset/hapt_data.mat','Xtrain','Ytrain','Xtest','Ytest');
    X              = [data.Xtrain, data.Xtest];
    [~,X]          = pca(X');
    X              = X';  X = X(1:10,:);
    D              = [data.Ytrain, data.Ytest];
    nx             = size(X,2); % data dimensions, #data points
    lat_length     = 15;      % lattice length
    lat_width      = 15;      % lattice width
    M              = lat_length*lat_width;    % number of nodes in lattice.
    N              = 1e1;     % maximum learning epochs.    
    tol            = 1;       % classification error percentage tolerance.
    log_events     = 4e2;     % total instants to log network parameters.
    plotlog_step   = 20;      % plot logs after 20 calls to the logger.
    log_step       = floor(N*nx/log_events);
    mu_init        = 0.1;     % learning rate.
    mu_final       = 0.01;    % min. learning rate.
    rad_init       = floor(min([lat_length,lat_width])/2); % initial neighborhood.
    rad_final      = 1;       % min. allowed radius.
    T              = 150;     % 1 epoch time
    mu_decay_fn    = make_hyperbolic_decay(T); % 1 epoch time constant 
    rad_decay_fn   = make_hyperbolic_decay(T); % 1 epoch time constant
    lattice        = make_rect_lattice(lat_width);%square lattice.
    learning_rate_schedule = make_schedule(mu_decay_fn, @(x)(x), ....
        mu_init,mu_final);
    radius_schedule = make_schedule(rad_decay_fn,@round,rad_init,rad_final);
    gaussian_neighborhood_function = ...
        make_gaussian_neighborhood_function(lattice, ...
        @(vi,vj)(sum(abs(vi-vj))), ...       
        radius_schedule);
    error_function = make_error_function();
    som_stop_predicate = make_stop_predicate(error_function,tol);
       
    %% create filenames/open output reporting files, figures
    ofile    = strcat(this_function,'out',fsuffix,'.txt');
    outfile  = fopen(ofile,'wt');
    fprintf('Performance characteristics will be printed in file: %s\n', ...
        ofile);
    fprintf(['Performance graphs will be plotted in files with ' ....
        'suffices: %s\n'],fsuffix);
    

    unique_class = length(unique(D));
    label_color = mat2cell(hsv(unique_class+1),ones(1,unique_class+1),3);
    label_text  = {'','WALKING','WALKING\_UPSTAIRS','WALKING\_DOWNSTAIRS',...
        'SITTING','STANDING','LAYING','STAND\_TO\_SIT','SIT\_TO\_STAND',...
        'SIT\_TO\_LIE','LIE\_TO\_SIT','STAND\_TO\_LIE','LIE\_TO\_STAND'};
    function fig = diag_plot(fig,W,tstr)
    % nested function. wrapper for plotting functions.
        fig = figure(fig);
        whitebg([0 0 0]);
        axis([1 lat_length+1 1 lat_width+1]);
        class_color = mat2cell(repmat([0 0 0],unique_class+1,1),...
            ones(1,unique_class+1),3);
        fig = decorate_class_color(fig,lattice,W,X,D,class_color,tstr,2);
        fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
        fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr,2);
        fig = decorate_class_label(fig,lattice,W,X,D,label_text,...
            label_color,5,tstr);
    end
    
    som_logger = make_logger(error_function,learning_rate_schedule,...
        radius_schedule,outfile,N,nx,tol,plotlog_step,...
        @diag_plot,'Smartphone Data',...
        strcat(this_function,'_',fsuffix));
    
    %% learn using som_learn
    [W,total_iter] = som_learn(X, M, gaussian_neighborhood_function, ... 
        learning_rate_schedule, N, som_stop_predicate, ...
        som_logger, log_step);
    
    %% Process results after training.
    fig = figure;
    axis([1 lat_length+1 1 lat_width+1]);
    whitebg([0 0 0]);
    tstr = 'Smartphone Data, Fence, weights and labels after training';
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
    fig = plot_mU(fig,1-colormap(gray),lat_width,W,tstr,2);
    fig = decorate_class_label(fig,lattice,W,X,D,label_text,...
            label_color,5,tstr);
    saveas(gcf,sprintf(['%sfig%d_after_training_mU_matrix_and_weights_'...
        '%s.fig'],this_function,fig,fsuffix));
    
    fig = figure;
    axis([1 lat_length+1 1 lat_width+1]);
    tstr = 'Smartphone Data, Class color map, labels and weights after training';
    colmapcell = label_color;
    label_color = mat2cell(repmat([1 1 1],unique_class+1,1),...
        ones(1,unique_class+1),3);
    fig = decorate_class_color(fig,lattice,W,X,D,colmapcell,tstr,0.1);
    fig = decorate_class_label(fig,lattice,W,X,D,label_text,...
            label_color,5,tstr);
    saveas(gcf,sprintf(['%sfig%d_after_training_classfication_'....
        'class_color_label_%s.fig'],this_function,fig,fsuffix));

    fig = figure;
    axis([1 lat_length+1 1 lat_width+1]);
    tstr = 'Smartphone Data, Class color map, labels and weights after training';
    fig = decorate_class_color(fig,lattice,W,X,D,colmapcell,tstr,0.1);
    fig = decorate_weight_vector(fig,lattice,W,tstr,[1 1 1],1);
    fig = decorate_class_label(fig,lattice,W,X,D,label_text,...
            label_color,5,tstr);
    saveas(gcf,sprintf(['%sfig%d_after_training_classfication_'....
        'class_color_label_weights_%s.fig'],this_function,fig,fsuffix));

    fprintf('Total learning steps: %d\n',total_iter);
    display('Finished problem for smartphone dataset');
end

%% som_learn function
function [W,iter] = som_learn(X,M,h,eta,N,stop_predicate,som_logger, ...
    log_step)
%% HEADER
%Run Kohonen SOM learning algorithm.
%
%INPUT
%   X : matrix: Input training data. Columns of this matrix correspond to 
%       input vectors.
%   M : scalar: Total number of lattice points/nodes. The nodes on lattice
%       have a running index = 1..M
%
%   stop_predicate: function handle: predicate to indicate if learning
%                   stops for current weights 'W' before max learn steps.
%                   It should take one argument, as in stop_predicate(W).
%                   W = current weights.
%
%   h : function handle: For neighborhood function. It should take four
%       arguments, as h('message',M,i,j).
%       M   = total number of nodes on the lattice (also see above).
%       i,j = optional args represent indices of two nodes on SOM lattice.
%       message = reset means initialize h.
%       message = next means move and get next value of h for i,j.
%       message = peek means get current value of h for i,j (don't move).
%
%   eta: function handle: Should take one argument, as eta('message')
%        message = reset means initialize eta.
%        message = next means move and get next learning rate per schedule.
%        message = peek means get current learning rate (but don't move).
%
%   N : scalar: maximum learning epochs for the algorithm to terminate.
%       epoch = number of data samples, known from size of X(see above).
%       max learn steps = N * number of data samples.
%
%   som_logger : function handle: callback function to report diagnostics.
%                It should take two parameters, as in som_report(iter,W).
%                iter = current learning step
%                W    = curretn weights
%
%   log_step : scalar: callback 'som_logger' every 'log_step' learn steps.
%
%RETURN
%   W : matrix: whose columns represnt the prototypes. The column indices
%       are equal to lattice node indices.
%
%   iter : scalar: number of learning steps (that is, learning stopped).
%%
    % pre-process input, initialize weights, other parameters.
    [mx,nx] = size(X);            % its better if pre-processing type is 
    X_mean = mean(X,2);           % also a parameter for som_learn.
    X_scale= max(abs(X(:)));
    X      = (X - repmat(X_mean,1,nx))/X_scale; % X is now normalized input 
    W = (max(X(:))-min(X(:)))*rand(mx,M,'double')+min(X(:));% initialialize weights. 
    h('reset');                          % initialize neighborhood function
    mu=eta('reset');                     % initialize learning rate.    
    iter = 0;                            % total iterations counter.
    
    for epoch = 1:N     % repeat and learn until convergence or max. steps.                
        for p = randperm(nx)
            % bokekeeping (call logger)
            if(mod(iter,log_step)==0)
                som_logger(iter,W*X_scale + repmat(X_mean,1,M));      
            end
%             i = (epoch-1)*N + p;
% radius = initRadius * ((i <= decayIters/5) + .8 * (i > decayIters/5 & i <= decayIters/2) + .5 * (i > decayIters/2 & i <= decayIters*.8)+ .2 * (i > decayIters*.8));
% alpha = alphaI * ((i <= decayIters/10) + .5 * (i > decayIters/10 & i <= decayIters/2.5) + .125 * (i > decayIters/2.5 & i <= decayIters*.8)+ .025 * (i > decayIters*.8));
            %1. stop learning if true.
            if(stop_predicate(W))
                return;
            end
            
            %2. find best match
            Q = (W - repmat(X(:,p),1,M)).^2;      % Euclidean distance 
            [~,c] = min(sum(Q,1));
            
            %3. update weights.
            for n = 1:M
                W(:,n) = W(:,n) + mu*h('peek',n,c)*(X(:,p) - W(:,n));
            end
            
            %4. next iteration, learning rate and neighborhood function.
            mu = eta('next');
            h('next');
            iter = iter+1;        
        end
    end

    W = W*X_scale + repmat(X_mean,1,M);
end

%% mU matrix
function fig = plot_mU(fig,fence_color,lat_wid,W,tstr,boundary_width)
%% Header
% Plot mU matrix. Only works for rectangular/square lattices.
% Input
%   fig : scalar : plotted in the figure.
%   fence_color : mx3 matrix : color map for the fence.
%   lat_wid : scalar : width of lattice.
%   W : matrix : prototype matrix (columns). Also prototype indices 1
%       through n are counted  columnwise on the lattice.
%   tstr : character string : plot title
% Return :
%   fig : scalar : figure window number.
%
    [dim,M] = size(W);
    lat_len = M/lat_wid;
    Wpad = nan*ones(lat_wid+2,lat_len+2,dim);  % 1 layer padding.
    Wpad(2:lat_wid+1,2:lat_len+1,:) = reshape(W',lat_wid,lat_len,dim);
    hdiff = Wpad(1:lat_wid+1,2:lat_len+1,:) - ...
        Wpad(2:lat_wid+2,2:lat_len+1,:);
    vdiff = Wpad(2:lat_wid+1,1:lat_len+1,:) - ...
        Wpad(2:lat_wid+1,2:lat_len+2,:); 
    
    % find distance. hdiff : horiontal neighbors, 
    hdiff = sqrt(sum(hdiff.^2,3)./sum(Wpad(1:lat_wid+1,2:lat_len+1,:).^2,3));
    
    % vdiff for vertical.
    vdiff = sqrt(sum(vdiff.^2,3)./sum(Wpad(2:lat_wid+1,1:lat_len+1,:).^2,3));
    [xg,yg] = meshgrid(1:lat_wid+1,1:lat_len+1);
    hdiff(isnan(hdiff)) = 0;
    vdiff(isnan(vdiff)) = 0;   
    scale = max([ max(abs(hdiff(:))), max(abs(vdiff(:))) ]);
    
    hdiff = 1-hdiff/scale;    % on gray scale, assume better matches 
    vdiff = 1-vdiff/scale;    % move to white.
    
    figure(fig);
    colormap(fence_color);
    
    %plot horizontal fences
    mesh(xg,yg,0*xg,hdiff,'EdgeColor','flat','LineWidth',boundary_width,...
        'FaceAlpha',0,'MeshStyle','row','Marker','none');
    hold on;
    grid off;
    
    %plot vertical fences
    mesh(xg,yg,0*xg,vdiff,'EdgeColor','flat','LineWidth',boundary_width,...
        'FaceAlpha',0,'MeshStyle','column','Marker','none');
    
    view([0 90]);      
    title(tstr);
end

%% class colors plot
function fig = decorate_class_color(fig,latf,W,X,D,class_color,tstr,...
    boundary_width)
%% Header
% Plot density and class colors. Density is transparency of the color.
% Input
%   fig : scalar: plots in this figure.
%   latf : function handle: lattice
%   W    : matrix: columns are prototypes.
%   X    : matrix: Input data matrix.
%   D    : vector: class labels (positive integers).
%   class_color : cell array : cell array having rgb triples for each
%                              class.
%   tstr : character string : plot title
%   boundary_width : scalar : vary boundary width of lattice edges.
% Return :
%   fig : scalar : figure window number.
%
    M = size(W,2);
    uniqD = unique(D);
    bin   = zeros(length(uniqD),M);
    nX    = size(X,2);
    get_class_index = @(p) (find(uniqD==D(p)));
    m_store = zeros(1,nX);
    c_store = zeros(1,nX);
    
    for p = 1:nX
        Q = (W - repmat(X(:,p),1,M)).^2;      % Euclidean distance 
        [~,m_store(p)] = min(sum(Q,1));
        c_store(p) = get_class_index(p);
        bin(c_store(p),m_store(p)) = bin(c_store(p),m_store(p)) + 1;
    end
    
    [density,majority_class] = max(bin,[],1);
    density_store = density;
    density(density~=0) = 1;                    % create a mask for colors.
    majority_class  = majority_class .* density + 1;
    
    v = [0 0; 1 0; 1 1; 0 1];
%     v = [0.1 0.1; 0.9 0.1; 0.9 0.9; 0.1 0.9];
    f = [1 2 3 4];
 
    fig=figure(fig);
    hold on;
    grid off;
    for i = 1:M
        ind = latf(i);
        ver = [ind(2)+v(:,1),ind(1)+v(:,2)];
        fa = density_store(i) / max(abs(density_store(:)));
        patch('Faces',f,'Vertices',ver, 'FaceColor',...
            class_color{majority_class(i)},'FaceAlpha',fa,...
            'LineWidth',boundary_width, 'LineStyle','-','EdgeColor','w');
    end

    title(tstr);
end

%% class text labels plot
function fig = decorate_class_label(fig,latf,W,X,D,label,label_color,...,
    label_fontsize,tstr)
%% Header
% Plot class label texts.
% Input
%   fig : scalar: plots in this figure.
%   latf : function handle: lattice
%   W    : matrix: columns are prototypes.
%   X    : matrix: Input data matrix.
%   D    : vector: class labels (positive integers).
%   label : cell array : cell array having text labels for each
%                              class.
%   label_color : cell array : cell array having rgb triples for each
%                              class.
%   label_fontsize : scalar : font size for label text
%   tstr : character string : plot title
% Return :
%   fig : scalar : figure window number.
%
    M = size(W,2);
    uniqD = unique(D);
    bin   = zeros(length(uniqD),M);
    nX    = size(X,2);
    get_class_index = @(p) (find(uniqD==D(p)));
    m_store = zeros(1,nX);
    c_store = zeros(1,nX);
    
    for p = 1:nX
        Q = (W - repmat(X(:,p),1,M)).^2;      % Euclidean distance 
        [~,m_store(p)] = min(sum(Q,1));
        c_store(p) = get_class_index(p);
        bin(c_store(p),m_store(p)) = bin(c_store(p),m_store(p)) + 1;
    end
    
    [density,majority_class] = max(bin,[],1);
    density(density~=0) = 1;
    majority_class  = majority_class .* density + 1; % create mask
    
    v = [0.2 0.2];
 
    fig=figure(fig);
    hold on;
    grid off;
    for i = 1:M
        ind = latf(i);
        ver = [ind(2)+v(1),ind(1)+v(2)];
        text(ver(:,1), ver(:,2),label{majority_class(i)}, ...
            'Color',label_color{majority_class(i)},'FontSize',...
            label_fontsize);
    end

    title(tstr);
end

%% weight vectors
function fig = decorate_weight_vector(fig,latf,W,tstr,line_color,line_width)
%% Header
% Decorate plot with weight vectors.  Plots the weight vectors in unit
% squares whose corner coordinates are given by lattice 'latf' (see below).
% INPUT:
%   fig : scalar : plotted in the figure.
%   latf : function handle : latf(i) gives co-ordinates for node 'i'.
%   W : matrix : prototype matrix (columns). Also prototype indices 1
%       through n are counted  columnwise on the lattice.
%   tstr : character string : plot title
%   line_color : 3-element vector : weights plotted with this color.
% RETURN :
%   fig : scalar : figure window number.
%
    [dim,M] = size(W);
    xval = 0.1:(0.8)/(dim+1):0.9;
    xval = xval(2:end-1);
    v = zeros(M,2);
    figure(fig);
    hold on;
    grid off;
    for i = 1:M
        v(i,:) = latf(i);
        y = (0.2)* (W(:,i)/max(abs(W(:,i)))) + 0.5;
        plot(xval+v(i,2), y+v(i,1),...
            'Color',line_color,'LineWidth',line_width);
    end
    title(tstr);
end
    
%% Factory method to make logging function.
 function logger = make_logger(ef,lrf,radf,outfile,N,nx,tol,plot_step,...
     plotf,plot_title,fsuffix)
 %% Header
 % INPUT:
 %  ef : function handle: error function with one argument (prototypes W)
 %  lrf : function handle: learning rate schedule with one argument,
 %                         lrf(message) message = {'peek','next','reset'}
 %                         that gets current/next value or resets it.
 %  radf : function handle: lattice neighborhood radius schedule. Like lrf
 %                          accepts one argument message.
 %  outfile : file handle: output written to this file.
 %  N : scalar : number of training epochs.
 %  nx : scalar : number of data samples.
 %  plot_step : scalar: plot logs after these many calls to logger
 %  plot_title : character string
 %  plotf : function handle: call this plot function as specified. It must
 %                           take three argument as plotf(fig,W,title);
 %  fsuffix : character string: plot figures saved with this filename
 %                              suffix.
 % RETURN
 %   logger : function handle: logging function for diagnostics.
    counter     = 0;
    
    function som_logger(iter,W)  
    %nested function to recall and record diagnostics while learning.
    %Passed as a function handle to som_learn.
    %INPUT
    %   iter : scalar: current iteration counter (iteration = learn step).
    %   W    : matrix: whose columns are current prototypes.
    %RETURN
    %   none.
        err  = ef(W);
        mu   = lrf('peek');
        rad  = radf('peek');

        for fid = [1, outfile]
            if(iter == 0)
                %Report network parameters
                fprintf(fid,'----------SOM LEARN STARTED----------\n');
                fprintf(fid,'***Initial weights***\n');
                print_weights(fid,W);
                fprintf(fid,'***Learning rate***\n');
                fprintf(fid,'\t%g\n', mu);
                fprintf(fid,'***Neighborhood radius***\n');
                fprintf(fid,'\t%d\n', rad);           
                fprintf(fid, ['***Stopping Criteria = max. learn_' ...
                    'steps OR error < tolerance***\n']);
                fprintf(fid,'\tMax learning steps\n');
                fprintf(fid,'\t%d\n',N*nx);
                fprintf(fid,'\tError Tolerance\n');
                fprintf(fid,'\t%g%%\n',tol);
                fprintf(fid,'***Initial Error***\n');
                fprintf(fid,'\t%g%%\n',err);
                fprintf(fid,['***Performance indicators while running ' ...
                    'SOM algorithm***\n']);
                fprintf(fid,['\titer: %-8d, learning_rate:%.6f, '...
                    'neighborhood_radius:%d, '...
                    'error:%g%%\n'], iter,mu,rad,err);
            else
                fprintf(fid,['\titer: %-8d, learning_rate:%.6f, '...
                    'neighborhood_radius:%d, '...
                    'error:%g%%\n'], iter,mu,rad,err);
            end
        end
        
        if(mod(counter,plot_step)== 0)
            fig  = figure;
            tstr = sprintf('%s, learn step: %d',plot_title,iter);
            fig  = plotf(fig,W,tstr);
%             pause(0.1);
%             saveas(gcf,sprintf('diagnostic_fig%d_%s.fig',fig,fsuffix));
        end
        
%         learn_steps(1 + iter/log_step) = iter;
%         error_history(1 + iter/log_step) = err;
        counter = counter+1;
    end
    logger = @som_logger;
 end
    
 %% make error_function --- RETURNS place holder NaN in this m-file.
 %                          Can be modified.
 function ef = make_error_function()
 %% Header
%factory method for stopping predicate, used by som_learn
%INPUT
%   none.
%RETURN
%   ef : function handle: error function.
%
%     function error = error_function(W)
%     %function to evaluate error given weights W, input X.
%     %Wrapper for classification_error_function defined below.
%     %INPUT
%     %   W : matrix: whose columns are current prototypes.
%     %   X : matrix: whose columns are data samples.
%     %RETURN
%     %   error : scalar: percentage of samples misclassified.
% %         error = classification_error_function(W,X,D);
% %         persistent Wlast;
% %         if(isempty(Wlast))
% %             Wlast = 0*W;
% %         end
% %         num = sqrt(sum((W-Wlast).^2,1));
% %         den = sqrt(sum(W.^2,1));
% %         error = 100*(std(num)/std(den) + mean(num)/mean(den))/2;
% %         Wlast = W;
%         error = nan;
%     end
    ef = @(W)(nan);
 end
 
%% factory method for stopping predicate, used by som_learn
function pred = make_stop_predicate(ef,tol)
%%
%factory method for stopping predicate, used by som_learn
%INPUT
%   ef : function handle: takes one argument W.
%   tol: scalar: acceptable error tolerance.
%RETURN
%   pred : function handle: predicate.
%
    pred = @(W)(ef(W) <= tol);
end
    
%% factory method for hyperbolic time decay
function decay_fn = make_hyperbolic_decay(T)
%% HEADER
%factory method for Hyperbolic time decay series generator.
%   T       : scalar: time scaling factor.
%RETURN
%   decay_fn : function handle: generates 1/(1+t/T), whre t is discrete.
%%
    myclock = make_discrete_time_clock();
    decay_fn = @(message)(1 / (1 + myclock(message)/T));
end
    
%% factory method for discrete time series (clock)
function dicrete_clock = make_discrete_time_clock()
%% HEADER
%factory method for discrete time series generator (clock).
%The clock has includes simple error recovery.
%On error, this m-file stops. The user may then choose to exit/continue.
%INPUT
%   T       : scalar: time scaling factor.
%RETURN
%   discrete_clock : function handle: generates 1/(1+t/T), whre t is discrete.
%%
    time = 0;     
    function discrete_time = inner_fn(message)
    %Input:
    %   message : character string: From the set {'reset','next','peek'}.
    %             If message = 'reset' ,reset time and return decay factor
    %             message = 'next' ,move time and retrun decay_factor.
    %             message = 'peek' ,return decay_factor at current time.
    %Return:
    %   discrete_time: scalar: discrete time starting from 0,1,2...
        if(isempty(time)) 
            time = 0;             % initialize.
        end
    
        switch message
            case 'reset'
                time = 0;         % initialize.
            case 'next'
                time = time+1;    % move one time step.
            case 'peek'           % do nothing.
            otherwise             % error handling.
                disp('ERROR : discrete_clock');
                disp('wrong argument passed for formal parameter message');
                disp('\t Expecting message = ''reset'' or ''next'' or ''peek'' ');
                fprintf('\t Got message = ''%s''\n', message);
                disp('You may choose to end the program');
                disp('\t<a href="MATLAB: dbquit;">Yes</a> / <a href="MATLAB: dbcont;">No</a>')
                keyboard;
        end
        discrete_time = time;
    end

    dicrete_clock = @inner_fn;
end

%% factory method for gaussian neighborhood function
function nf = make_gaussian_neighborhood_function(latf,distf,radf)
%% HEADER
%Gaussian neighborhood function schedule
%INPUT
%   latf  : function handle: lattice.
%   distf : function handle: distance (euclidean,manhattan,...etc)
%   radf  : function handle: radius schedule
%RETURN
%   nf : function handle: gaussian neighborhood function.
    function r = inner_gaussian(message,varargin)
    %Gaussian neighborhood function schedule
    %INPUT
    %   message : character string: from the set {'reset','next','peek'}.
    %   varargin: scalars: optional parameters, i and j, indexing two nodes
    %             on SOM lattice.
    %             If message = 'reset' , i and j are ignored and return 0.
    %             message = 'next' , move the schedule and return distance
    %                       between lattice nodes i and j (if provided).
    %             message = 'peek' , return distance between lattice nodes 
    %                       i and j.
    %RETURN
    %   r : scalar: neighborhood function value for two nodes on lattice.
        numvarargs = length(varargin);      % at most 2 optional args.
        if (numvarargs > 2)
            error('ERROR:gaussian_neighborhood_function:TooManyInputs', ...
            'requires at most 2 optional inputs');
        end
        ij = {1 1};                       % set defaults for optional args.
        ij(1:numvarargs) = varargin;      % overwrite arguments provided.
        dist = distf(latf(ij{1}),latf(ij{2}));  % distance between i and j.
        rad = radf(message);
        r = exp(-dist^2 / 2 / rad^2);
    end
    nf = @inner_gaussian;
end

%% factory method for making schedule
function schedule = make_schedule(df,tf,init,final)
%% HEADER
%INPUT
%   df    : function handle: decay function
%   tf    : function handle: transform
%   init  : scalar: initial value.
%   final : scalar: initial value.
%RETURN
%   schedule : function_handle: A schedule start from 'init' to 'final'
%              decaying as 'df'. Then, transform 'tf' is applied.
    schedule = @(message)(tf((init-final)*df(message)+final));
end

%% factory method for 2D rectangular lattice
function lattice = make_rect_lattice(wid)
%% HEADER
%factory method, generates 2D rectangular lattice of area M.
%INPUT
%   wid : scalar: width
%RETURN
%   lattice : function handle: accepts one argument.
    %%
    function ind = rect_lattice(i)
        %INPUT
        %   i : scalar: running index of node on the lattice.
        %RETURN
        %   ind : vector: rectangular co-ordinates of the node. 
        %%
        col = floor((i-1)/wid) + 1;   % i starts at top left of the
        row = mod(i-1,wid) + 1;       % 2D SOM array and runs downwards!
        ind = [row, col];
    end
    lattice = @rect_lattice;
end

%% Classfication error function - Not used in this m-file.
function perr = classification_error_function(W,X,D)
%% HEADER
%Evaluate classification error given prototypes W, input X, and desired
%output D. First step, use majority rule to assign a node on SOM lattice to
%a class. On second step, run the input X agaain, and count classfication
%errors.
%INPUT
%   W     : matrix: whose columns are current prototypes.
%   X     : matrix: whose columns are input data samples.
%   D     : vector: class labels corresponding to X.
%RETURN
%   perr  : scalar: percentage of misclassified samples. 
%%
    nodes = size(W,2);
    uniqD = unique(D);
    bin   = zeros(length(uniqD),nodes);
    nX    = size(X,2);
    get_class_index = @(p) (find(uniqD==D(p)));
    m_store = zeros(1,nX);
    c_store = zeros(1,nX);
    
    for p = 1:nX
        m_store(p) = best_match_node(W,X(:,p));
        c_store(p) = get_class_index(p);
        bin(c_store(p),m_store(p)) = bin(c_store(p),m_store(p)) + 1;
    end
    
    [density,classification_map] = max(bin,[],1);
    density(density~=0) = 1;
    classification_map  = classification_map .* density;
    errors = 0;
    for p = 1:nX
        if(c_store(p) ~= classification_map(m_store(p)))
            errors = errors + 1;
        end      
    end
    
    perr = 100*errors/nX;    
end

%% Helper function to find best match node
function match = best_match_node(W,x)
%% HEADER
%Find and return best matching node index using L2 norm distance.
%INPUT
%   W     : matrix: whose columns are current prototypes.
%   x     : vector: data sample.
%RETURN
%   match : scalar: index of node with best match. 
%%
    Q = (W - repmat(x,1,M)).^2;      % Euclidean distance 
    [~,match] = min(sum(Q,1));
end

%% Helper for logging function to print current set of prototypes
function print_weights(ofile,W)
%% HEADER
%Function to print current set of weights ot ofile.
%Used as a helper function for printing weights. For example, this is used
%by the function som_report).
%INPUT
%   ofile : scalar: output file (weights will be printed to this file)
%                   It is assumed to be open.
%   W     : matrix: whose columns are current prototypes.
%RETURN
%   none. No return value (this function only has side effects).  
%%
    fprintf(ofile,[repmat('\t%+8.6f ',1,size(W,2)) '\n'],W);             
end

%% Data generator for problem 2a
function [X,D] = generate_data_prob2a(npoints)
%% HEADER
%Generate datasets for homework6 problem2b, 2D Gaussian
%vectors, all datasets have variance 0.1 and means (0,0) (0,7) (7,0)
%and (7,7).
%
%INPUT
%   npoints : scalar: number of data points in each dataset.
%RETURN
%   X : matrix: [X1, X2, X3, X4]
%       Each of X1, X2, X3, X4 are matrices of size [3,npoints].
%       X1 = 3D gaussian with variance 0.1 and mean (0,0).
%       X2 = 3D gaussian with variance 0.1 and mean (0,7).
%       X3 = 3D gaussian with variance 0.1 and mean (7,7).
%       X4 = 3D gaussian with variance 0.1 and mean (7,0).
%   D : vector: class labels {1,2,,3,4}.
%%
    persistent x1;
    persistent x2;
    persistent x3;
    persistent x4;
    persistent d;
    stored_points = -1;
    
    if(~isempty(x1))
        stored_points = size(x1,2);
    end
    
    if( npoints == stored_points ...
             && ~(isempty(x1) || isempty(x2) || isempty(x3) || isempty(x4)) ...
             && ~(isempty(d)) )
        X = [x1, x2, x3, x4];
        D = d;
        return;
    end
    
    if(isempty(x1))                %variance = 0.1, centered at (0, 0)
        x1=sqrt(0.1)*randn(2,npoints);
        x1=detrend(x1')';
    end
      
    if(isempty(x2))                %variance = 0.1, centered at (0, 7)
        x2=sqrt(0.1)*randn(2,npoints);
        x2=detrend(x2')';
        x2(2,:)=x2(2,:) + 7*ones(1,npoints);        
    end
    
    if(isempty(x3))                %variance = 0.1, centered at (7, 7)
        x3=sqrt(0.1)*randn(2,npoints);
        x3=detrend(x3')';
        x3(1,:)=x3(1,:) + 7*ones(1,npoints);       
        x3(2,:)=x3(2,:) + 7*ones(1,npoints);        
    end
     
    if(isempty(x4))                %variance = 0.1, centered at (7, 0)
        x4=sqrt(0.1)*randn(2,npoints);
        x4=detrend(x4')';
        x4(1,:)=x4(1,:) + 7*ones(1,npoints);        
    end
    
    if(isempty(d))
        v = ones(1,npoints);
        d = [v,2*v,3*v,4*v];
    end
    
    X = [x1, x2, x3, x4];
    D = d;
end

%% Data generator for problem 2b
function [X,D] = generate_data_prob2b(npoints)
%% HEADER
%Generate datasets for homework6 problem2b, 3D Gaussian
%vectors, all datasets have variance 0.1 and means (0,0,0) (0,7,0) (7,0,0)
%and (7,7,0).
%
%INPUT
%   npoints : scalar: number of data points in each dataset.
%RETURN
%   X : matrix: [X1, X2, X3, X4]
%       Each of X1, X2, X3, X4 are matrices of size [3,npoints].
%       X1 = 3D gaussian with variance 0.1 and mean (0,0,0).
%       X2 = 3D gaussian with variance 0.1 and mean (0,7,0).
%       X3 = 3D gaussian with variance 0.1 and mean (7,7,0).
%       X4 = 3D gaussian with variance 0.1 and mean (7,0,0).
%   D : vector: class labels {1,2,,3,4}.
%%
%
    persistent x1;
    persistent x2;
    persistent x3;
    persistent x4;
    persistent d;
    stored_points = -1;
    
    if(~isempty(x1))
        stored_points = size(x1,2);
    end
    
    if( npoints == stored_points ...
             && ~(isempty(x1) || isempty(x2) || isempty(x3) || isempty(x4)) ...
             && ~(isempty(d)) )
        X = [x1, x2, x3, x4];
        D = d;
        return;
    end
    
    if(isempty(x1))                %variance = 0.1, centered at (0, 0, 0)
        x1=sqrt(0.1)*randn(3,npoints);
        x1=detrend(x1')';
    end
      
    if(isempty(x2))                %variance = 0.1, centered at (0, 7, 0)
        x2=sqrt(0.1)*randn(3,npoints);
        x2=detrend(x2')';
        x2(2,:)=x2(2,:) + 7*ones(1,npoints);        
    end
    
    if(isempty(x3))                %variance = 0.1, centered at (7, 7, 0)
        x3=sqrt(0.1)*randn(3,npoints);
        x3=detrend(x3')';
        x3(1,:)=x3(1,:) + 7*ones(1,npoints);       
        x3(2,:)=x3(2,:) + 7*ones(1,npoints);        
    end
     
    if(isempty(x4))                %variance = 0.1, centered at (7, 0, 0)
        x4=sqrt(0.1)*randn(3,npoints);
        x4=detrend(x4')';
        x4(1,:)=x4(1,:) + 7*ones(1,npoints);        
    end
    
    if(isempty(d))
        v = ones(1,npoints);
        d = [v,2*v,3*v,4*v];
    end
    
    X = [x1, x2, x3, x4];
    D = d;
end

%% Data generator for problem 4
function [X, D] = generate_data_prob4
%% HEADER
%Generate dataset for homework6 problem4 (iris dataset).
%INPUT
%   no input (however, the iris data ascii files must be present in same
%   directory as this m file).
%RETURN
%   [X,D] = input vectors in matrix 'X' column-wise and corresponding 
%           class labels in matrix 'D'
%%
%
    ftrain = fopen('iris-train.txt','rt');
    ftest  = fopen('iris-test.txt','rt');

    persistent train_data;
    persistent test_data;

    if(isempty(train_data))
        display(['reading iris training dataset from file iris-train.txt'...
            'for Homework6, problem4']);
        train_data = textscan(ftrain,'%f%f%f%f\n&%f%f%f\n','HeaderLines',8);
    end
    if(isempty(test_data))
        display(['reading iris training dataset from file iris-test.txt'...
            'for Homework6, problem4']);
        test_data = textscan(ftest,'%f%f%f%f\n&%f%f%f\n','HeaderLines',8);
    end

    xtrain = [train_data{1}, train_data{2},train_data{3}, train_data{4}]';
    dtrain = [train_data{5}, train_data{6}, train_data{7}]';
    xtest  = [test_data{1}, test_data{2},test_data{3}, test_data{4}]';
    dtest  = [test_data{5}, test_data{6}, test_data{7}]';

    X = [xtrain, xtest];
    D = [dtrain, dtest];
    [~,D] = max(D,[],1);

end
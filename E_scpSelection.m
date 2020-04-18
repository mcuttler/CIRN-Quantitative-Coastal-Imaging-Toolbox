%% E_stabilizationSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This function initializes the SCP (stabilization control points) 
%  structure for a given camera for use in the CIRN BOOTCAMP TOOLBOX.  
%  The user will load a given DISTORTED image for where the IOEO has been
%  calcuated already using C_singleExtrinsicSolution and then select at
%  least X  bright points that will be used to stabilize the image. 
%  Additional parameters such as expected movement radius and intensity 
%  threshold will also be entered.

%  The clicking mechansism works similar to B_gcpSelection. The user can
%  zoom and move the image until they hit enter to go into clicking mode
%  (cross-hairs). Note, the click does not have to be as precise as
%  B_gcpSelection. The user should click a bright target that is brighter
%  than what is around it and does not move. (Not in the water with
%  breaking waves rushing past). The user will enter a SCP number, and 
%  radius (in pixels) to search for the point. It is best to be as small as 
%  possible and not include bright pixels of other objects. For example, if
%  on a pier, the radius should be small enough to exclude any water
%  pixels. The radius should  appear in the figure after entry. Hit enter with an empty input when
%  done. 
%  
%  Then the user will enter a threshold value  in the command window
%  deliminating bright points from dark points, it is the center of the
%  bright points that will be considered the SCP point. This will be
%  updated in anew figure to show the estimated SCP center. If the threshold 
%  is very high, it is probably not a good SCP point and may error if any 
%  slight changes in pixel value (>245). Hit enter with
%  an empty value when complete. When done with selection go in to clicking
%  mode and click below the X axis. The user should pick at least 4 points.
%  Note, if GCPs selected, SCP point numbers do not have to match.

%  Reference Slides:
%  

%  Input:
%  Entered by user below in Sections 1-2. In Section 1 the user will input
%  output names. Section 2 will require the location of the oblique imagery
%  to be stabilized. 


%  Output:
%  A mat file with the SCP structure and figure with selected control 
%  points and boundaries. scpUVdInitial will be appended to the output
%  name.

%  Required CIRN Functions:
%  none



%  Required MATLAB Toolboxes:
%  none


%  This function is to be run fifth in the CIRN BOOTCAMP TOOLBOX
%  progression to identify stabilization control points (SCP) for collections
%  of imagery where the camera may have moved. For UAS it should be run on 
%  the first image used for camera IOEO calibration. For fixed camera 
%  stations, tyring to correct for movement, it should be run on the last 
%  known image where the IOEO is known to be valid. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Housekeeping
close all
clear all




%% Section 1: User Input:  Output

%  Enter the filename of the gcp .mat file that will be saved as. Name 
%  should be descriptive of the collection.
oname='uasDemo';

%  Enter the directory where the mat file will be saved.
odir= '.\X_UASDemoData\extrinsicsIntrinsics\InitialValues';





%% Section 2: User Input: SCP Image
%  Enter the filepath of the saved image for clicking. For a collection
%  where the camera moves, it should be the image used for IOEO initial
%  calibration in C_singleExtrinsic Solution and B_gcpSelection(imagePath).
imagePath= '.\X_UASDemoData\collectionImages\uasDemoFlight\00001000.jpg';





%% Section 4: Clicking and Saving SCPS.
    
if isempty(imagePath)==0

    % Display Image    
    f1=figure;
    
    I=imread(imagePath);
    [r c t]=size(I);

    imagesc(1:c,1:r,I)
    axis equal
    xlim([0 c])
    ylim([0 r])
    xlabel({ 'Ud';'Click Here in Cross-Hair Mode To End Collection '})
    ylabel('Vd')
    hold on

    % Clicking Mechanism
    x=1;
    y=1;
    button=1;
    UVclick=[];

    while x<=c & y<=r % Clicking figure bottom will end clicking opportunity

        % Allow User To Zoom
        title('Zoom axes as Needed. Press Enter to Initiate Click')
        pause

        % Allow User to Click
        title('Left Click to Save. Right Click to Delete')
        [x,y,button] = ginput(1);


        % If a left click, ask user for parameters, display and store
        if button==1  & (x<=c & y<=r) 
            
            
            title('Enter SCP Parameters in Command Window')
            
            % User Input for Number
            num=input('Enter SCP Number:');
                % Display SCP Number In Image
                text(x+30,y,num2str(num),'color','r','fontweight','bold','fontsize',15)

            % User Input for UVd Pixel Radius
                % Allows user to input various values and display until one
                % is satisfactory. (Its really a square width, not radius)
                Rn=75;
                h=rectangle('position',[x-Rn,y-Rn,2*Rn,2*Rn],'EdgeColor','r','linewidth',1);
                while isempty(Rn)==0
                R=Rn;
                Rn=input('MovementRadius,leave empty if previous entry satisfactory:');
                if isempty(Rn)==0
                h.Position=[x-Rn,y-Rn,2*Rn,2*Rn];
                end
                end

            % User Input for Threshold
                % Allows user to input various values and display effect
                % until one is satisfactory. Will show effects in new
                % figure.

                % Initialize New Figure and subplots
                Tn=100;
                f2=figure;
                
                    % Image as is.
                    subplot(121)
                    hold on
                    title(['SCP: ' num2str(num) 'Intensities'])
                    colorbar
                    colormap jet
                    axis equal
                    

                    % Thresholded Image
                    subplot(122)
                    title(['SCP: ' num2str(num) '. Threshold:' num2str(Tn)])
                    hold on
                    hold on
                    colormap jet
                    axis equal
            

                % While the entered threshold value is not empty...user can
                % enter new values. 

                while isempty(Tn)==0
                    %Initiate Values
                    T=Tn;
                    % Calculate New Center of Area (Udn,Vdn) given Threshold T
                    [ Udn, Vdn, i, udi,vdi] = thresholdCenter(I,x,y,R,T);
                    
                    % Plot Calculated Subset, Image, and new Centers of
                    % ROI in regular image
                    subplot(121)
                    imagesc(udi,vdi,i), set(gca,'ydir','reverse')
                    p1=plot(Udn,Vdn,'ko','markersize',10,'markerfacecolor','w');
                    p1.XData=Udn;
                    p1.YData=Vdn;
                    xlim([udi(1) udi(end)])
                    ylim([vdi(1) vdi(end)])
                    % Plot Calculated Subset, Image, and new Centers of ROI
                    % In Thresholded image
                    subplot(122)
                    imagesc(udi,vdi,i>T), set(gca,'ydir','reverse')
                    title(['SCP: ' num2str(num) '. Threshold:' num2str(Tn)])
                    p2=plot(Udn,Vdn,'ko','markersize',10,'markerfacecolor','w');
                    p2.XData=Udn;
                    p2.YData=Vdn;
                    xlim([udi(1) udi(end)])
                    ylim([vdi(1) vdi(end)])
                    
                    % Have user Enter New Value
                    Tn=input('Color Threshold,leave empty if previous entry satisfactory:');
                end
                % Close New Figure when user decides value
                close(f2)




            % Store Entered and Clicked Values
            UVclick=cat(1,UVclick, [num x y  R T Udn Vdn]);
            
           
            % Display Values
            disp(['SCP ' num2str(num) ' [Udo Vdo]= [' num2str(Udn) ' ' num2str(Vdn) ']'])
            disp(' ')

            % Make f1 current figure and in original view.
            figure(f1)
            zoom out
        end   
        
        % If a right click, program will delete nearest point, mark UVClick
        % Entry as unusable with value -99.
        if button==3 & (x<=c & y<=r) 
            % Find Nearest Marker 
            Idx = knnsearch(UVclick(:,2:3),[x y]);
            
            % Turn the visual display off.
            N=length(UVclick(:,1,1))*2+1; % Total Figure Children (Image+ 1 Text + 1 Marker for each Click)
            f1.Children(1).Children(N-(Idx*2)).Visible='off';   % Turn off Text
            f1.Children(1).Children(N-(Idx*2-1)).Visible='off'; % Turn off Marker
            
            %Display Deleted GCP
            disp(['Deleted SCP ' num2str(UVclick(Idx,1))]);
            
            % Set UVclick GCP number to Unusable Value
            UVclick(Idx,1)=-99;
            zoom out
        end

               

    end
     
    % Filter out values that were to be deleted
    IND=find(UVclick(:,1) ~= -99);
    UVsave=UVclick(IND,:);
    
    % Sort so SCP Numbers are in order
    [ia ic]=sort(UVsave(:,1));
    UVsave(:,:)=UVsave(ic,:);
    
    % Place in SCP Format ( Will Just save Center of Area Values)
    for k=1:length(UVsave(:,1))
        scp(k).UVdo=UVsave(k,6:7);
        scp(k).num=UVsave(k,1);
        scp(k).R=UVsave(k,4);
        scp(k).T=UVsave(k,5);
    end
    

end





%% Section 5: Display Results
disp(['SCPs Entered for ' oname ':'])
disp(' ')

for k=1:length(scp)
    disp(['scp(' num2str(k) ').num = ' num2str(scp(k).num(1)) ] )  
    disp(['scp(' num2str(k) ').UVdo = [' num2str(scp(k).UVdo(1)) ' ' num2str(scp(k).UVdo(2)) ']'])   
    disp(['scp(' num2str(k) ').R = ' num2str(scp(k).R(1)) ] )  
    disp(['scp(' num2str(k) ').T = ' num2str(scp(k).T(1)) ] )  
    disp(' ')
end





%% Section 6: Save File

% Incorporate imagePath in structure
for k=1:length(scp)
    scp(k).imagePath=imagePath;    
end

% Save Results
save([odir '/' oname '_scpUVdInitial' ],'scp')





%% Copyright Information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Copyright (C) 2017  Coastal Imaging Research Network
%                       and Oregon State University

%    This program is free software: you can redistribute it and/or  
%    modify it under the terms of the GNU General Public License as 
%    published by the Free Software Foundation, version 3 of the 
%    License.

%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.

%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see
%                                <http://www.gnu.org/licenses/>.

% CIRN: https://coastal-imaging-research-network.github.io/
% CIL:  http://cil-www.coas.oregonstate.edu
%
%key UAVProcessingToolbox





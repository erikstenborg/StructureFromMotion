
%OBJECT TYPES
%1 - cocacola pet 1.5 litre
%2 - cocacola light pet 1.5 litre
%3 - cocacola can 33 cl
%4 - blueberry soup
%5 - blackberry soup


%bib='C:\Users\fredrik\Documents\MATLAB\sfm_library\data\InstanceRecognition\instance_sequences\';
%bib='C:\Users\fredrik\Dropbox\tmp\Lucas\InstanceRecognition\instance_sequences\';
bib='/home/lucas/instance_deps/InstanceRecognition/instance_sequences/';

file='GOPR1830/';





%load settings and result file
% load([bib,file,'result.mat']);
% eval(['load ',bib,file,'result_anno.mat']);
load result_anno_updated_path


% Create data structure to determine the source of all points in U & u_uncalib
lookups = struct();
% Indices for all SFM points
lookups.sfm = create_lookups(U, u_uncalib);




% Add points for shelves and update reconstruction
% [u_uncalib,U]=add_1point(settings,P_uncalib,U,u_uncalib,[1,4,44,48]);
% [U,P_uncalib,lambda] = modbundle_sparse(U,P_uncalib,u_uncalib,10,10);
load result1_shelves_and_updated_cameras
lookups.shelves = struct('U_idx', {}, 'u_idx', {});
lookups.shelves(1) = create_lookups(U, u_uncalib, [1,4,44,48], 6, 6+5);
lookups.shelves(2) = create_lookups(U, u_uncalib, [1,4,44,48], 6, 5);
lookups.shelves(3) = create_lookups(U, u_uncalib, [1,4,44,48], 5, 0);




% Add points for upper right shelf of bottles.
% Bottles from right to left. 4 regular Coca-Cola, followed by 3 Coca-Cola Zero.
% [u_uncalib,U]=add_1point(settings,P_uncalib,U,u_uncalib,[60,68,44,48]);
load result2a_upper_right_bottles
lookups.right_shelf_bottles = create_lookups(U, u_uncalib, [60,68,44,48], 7);


% Add points for upper left shelf of bottles.
% Bottles from right to left. 6 regular Coca-Cola, followed by 2 Coca-Cola Zero.
% [u_uncalib,U]=add_1point(settings,P_uncalib,U,u_uncalib,[210,220,230,290]);
load result2b_upper_left_bottles
lookups.left_shelf_bottles = create_lookups(U, u_uncalib, [210,220,230,290], 8);



mesh = struct();
labels = struct();

mesh.shelves = struct('tri', {}, 'U', {});
%add bookshelf 1
[mesh.shelves(1).tri, mesh.shelves(1).U] = annotate_addshelf(U(1:3, lookups.shelves(1).U_idx), [1,22,26,27,25,21]);

%add bookshelf 2
% mesh.shelves(2) = struct();
[mesh.shelves(2).tri, mesh.shelves(2).U] = annotate_addshelf(U(1:3, lookups.shelves(2).U_idx), [22,2,1,26,25,7]);

%add bookshelf 3
% mesh.shelves(3) = struct();
[mesh.shelves(3).tri, mesh.shelves(3).U] = annotate_addshelf(U(1:3, lookups.shelves(3).U_idx), [2,6,1,25,22]);


% %blue berry covers
% tribox = [1,2,3;1,3,4;3,4,7;4,7,8;5,6,7;5,7,8;5,8,9;10,11,12;11,13,12;7,8,12;8,12,13]';
% 
% Utmp = U(1:3,nbrpoints_sfm+[20:31]);
% %small fix of one point
% v1=U(1:3,nbrpoints_sfm + 29)-U(1:3,nbrpoints_sfm + 30);v2=U(1:3,nbrpoints_sfm + 31)-U(1:3,nbrpoints_sfm + 30);n=cross(v1,v2);n=n/norm(n);
% Utmp(:,11)=Utmp(:,11)+0.00008*n;
% 
% 
% 
% 
% v1 = Utmp(:,11)-Utmp(:,10);
% v2 = Utmp(:,12)-Utmp(:,10);
% Utmp = [Utmp,(Utmp(:,11)+v2+Utmp(:,12)+v1)/2];
% tri = [tri,tribox+size(Utri,2)];
% Utri = [Utri,Utmp];
% 
% %coca cola cans cover
% tribox = [1,2,3;1,3,4;3,4,6;4,5,6;5,6,7;5,7,8]';
% 
% Utmp = U(1:3,nbrpoints_sfm+[32:39]);
% tri = [tri,tribox+size(Utri,2)];
% Utri = [Utri,Utmp];






% ADD OBJECTS
%labels
instance_cnt=0;


%bottles
alpha = 0:0.4:2*pi;rr = 0.13;height=0.8;nn=length(alpha);
Ubottle=[rr*cos(alpha),rr*cos(alpha),0;rr*sin(alpha),rr*sin(alpha),0;zeros(size(alpha)),height*ones(size(alpha)),1];
tribottle = [1:nn,      nn+1:2*nn, 2*nn+1*ones(1,nn) ; ...
             [2:nn,1],  [nn+2:2*nn,nn+1]  , nn+1:2*nn, ;...
             nn+1:2*nn, [2:nn,1]       , [nn+2:2*nn,nn+1]];
%figure(1);clf;trisurf(tribottle',Ubottle(1,:),Ubottle(2,:),Ubottle(3,:));axis equal;rotate3d on;



% Upper right shelf with bottles

mesh.right_shelf_bottles = struct('tri', {}, 'U', {});

labels.right_shelf_bottles = struct();
% 4 Regular Coca-Cola bottles, 3 Coca-Cola Zero bottles
labels.right_shelf_bottles.class_labels = [1,1,1,1,2,2,2];
labels.right_shelf_bottles.instance_labels = zeros(1,0);

pl = get_plane(mesh.shelves(1).U, 1);
n = pl(1:3);


for j=1:length(lookups.right_shelf_bottles.U_idx),
    ii = lookups.right_shelf_bottles.U_idx(j);
    instance_cnt = instance_cnt+1;
    ll = -n'*U(1:3,ii)-pl(4);
    Uplane = U(1:3,ii)+ll*n;

    sc = norm(Uplane-U(1:3,ii));

    R = [null(n'), n]; if det(R)<0,R=[R(:,2),R(:,1),R(:,3)];end
    T = [sc*R,Uplane;[0,0,0,1]];

    Utmp=T(1:3,:)*pextend(Ubottle);

    mesh.right_shelf_bottles(j).tri = tribottle;
    mesh.right_shelf_bottles(j).U = Utmp;
    labels.right_shelf_bottles.instance_labels = [labels.right_shelf_bottles.instance_labels,instance_cnt*ones(1,size(tribottle,2))];
end




% Upper left shelf with bottles

mesh.left_shelf_bottles = struct('tri', {}, 'U', {});

labels.left_shelf_bottles = struct();
% 6 Regular Coca-Cola bottles, 2 Coca-Cola Zero bottles
labels.left_shelf_bottles.class_labels = [1,1,1,1,1,1,2,2];
labels.left_shelf_bottles.instance_labels = zeros(1,0);

pl = get_plane(mesh.shelves(3).U, 1);
n = pl(1:3);

for j=1:length(lookups.left_shelf_bottles.U_idx),
    ii = lookups.left_shelf_bottles.U_idx(j);
    Upp = U(1:3,ii);
    instance_cnt=instance_cnt+1;
    ll = -n'*Upp-pl(4);
    Uplane = Upp+ll*n;

    sc = norm(Uplane-Upp);

    R = [null(n'), n]; if det(R)<0,R=[R(:,2),R(:,1),R(:,3)];end
    T = [sc*R,Uplane;[0,0,0,1]];

    Utmp=T(1:3,:)*pextend(Ubottle);

    mesh.left_shelf_bottles(j).tri = tribottle;
    mesh.left_shelf_bottles(j).U = Utmp;
    labels.left_shelf_bottles.instance_labels = [labels.left_shelf_bottles.instance_labels,instance_cnt*ones(1,size(tribottle,2))];
end



% Merge mesh
[tri, Utri] = merge_mesh(mesh.shelves);

[triobj, Uobj] = merge_mesh([ ...
    mesh.right_shelf_bottles, ...
    mesh.left_shelf_bottles]);

% Merge labels
instance_labels = [ ...
    labels.right_shelf_bottles.instance_labels, ...
    labels.left_shelf_bottles.instance_labels];
class_labels = [ ...
    labels.right_shelf_bottles.class_labels, ...
    labels.left_shelf_bottles.class_labels];

% THE FOLLOWING IS OLD
STOP_HERE



%saft soppa
alpha = 0:0.4:2*pi;rr = 1.5;height=1;nn=length(alpha);
cc = [3.75,2.0];

th = atan(1.5/7.0);
Usaft=[rr*cos(alpha),rr*cos(alpha),0;rr*sin(alpha),rr*sin(alpha),0;zeros(size(alpha)),height*ones(size(alpha)),1];
ccindex = size(Usaft,2);

Usaft(1,:)=Usaft(1,:)+cc(1);
Usaft(2,:)=Usaft(2,:)+cc(2);

R = [1,0,0;0,cos(th),sin(th);0,-sin(th),cos(th)];

Usaft = R'*Usaft;
trisaft = [1:nn,      nn+1:2*nn, 2*nn+1*ones(1,nn) ; ...
             [2:nn,1],  [nn+2:2*nn,nn+1]  , nn+1:2*nn, ;...
             nn+1:2*nn, [2:nn,1]       , [nn+2:2*nn,nn+1]];
         
Uframe = [0,0,0;7.5,0,0;7.5,7.0,1.5;0,7.0,1.5;0,0,-18.8;7.5,0,-18.8;7.5,7.0,-18.8;0,7.0,-18.8]';
trisaft(:,end+[1:12])=size(Usaft,2)+[1,2,3;1,3,4;5,6,7;5,7,8;1,2,5;2,5,6;2,3,7;2,7,6;3,4,7;4,7,8;1,5,8;1,8,4]';
Usaft = [Usaft,Uframe];
Ucc = Usaft(:,ccindex);


%plane of saft soppa
v1 = mesh.shelves(2).U(:,26)-mesh.shelves(2).U(:,25);
v2 = mesh.shelves(2).U(:,27)-mesh.shelves(2).U(:,26);
v3 = mesh.shelves(2).U(:,27)-mesh.shelves(2).U(:,26);
v4 = mesh.shelves(2).U(:,14)-mesh.shelves(2).U(:,12);

n = cross(v1,v2);n= n/norm(n);
n2 = cross(v3,v4);n2= n2/norm(n2);

%n = n + 0.05*n2;n=n/norm(n);
pl = [n;-n'*mesh.shelves(2).U(:,25)-0.0001];

cc = 0;
for ii=nbrpoints_anno+[16:30],
    Upp = U(1:3,ii);
    instance_cnt=instance_cnt+1;
    cc = cc +1;
    if cc==5,
        cc=1;
    end
    if cc<=8,
        class_labels(instance_cnt) = 5; %blackberry
    else
        class_labels(instance_cnt) = 4; %blueberry
    end
        
    ll = -n'*Upp-pl(4);
    Uplane = Upp+ll*n;

    sc = norm(Uplane-Upp)/norm(-18.8-Ucc(3));

    R = [null(n'), n]; if det(R)<0,R=[R(:,2),R(:,1),R(:,3)];end
    
    tmp = R'*n2;
    tmp(3)=0;tmp=tmp/norm(tmp);
    th2 = atan2(tmp(1),tmp(2))+3*pi/2;
    R = R*[cos(th2),sin(th2),0;-sin(th2),cos(th2),0;0,0,1];
    
    tt = Uplane - sc*R*[3.75;cos(th)*2.0;-18.8];
    T = [sc*R,tt;[0,0,0,1]];

    Utmp=T(1:3,:)*pextend(Usaft);

    triobj = [triobj,trisaft+size(Uobj,2)];
    Uobj=[Uobj,Utmp];
    instance_labels=[instance_labels,instance_cnt*ones(1,size(trisaft,2))];
end



%three packages in random position
pl = [n;-n'*mesh.shelves(2).U(:,25)];
class_labels = [class_labels,4,5,5];
for ii=nbrpoints_anno+[31:2:36],
    Upp1 = U(1:3,ii);
    Upp2 = U(1:3,ii+1);
    jj=(ii-nbrpoints_anno-31)/2;
    Upp = U(1:3,nbrpoints_anno+37+jj);
    
    if ii==nbrpoints_anno+31,
        nn = Upp2-Upp1;
        Upp = Upp+0.015*nn;
    end
    
    
    instance_cnt=instance_cnt+1;
        
    ll = -n'*Upp-pl(4);
    Uplane = Upp+ll*n;
    
    ll1 = -n'*Upp1-pl(4);
    Uplane1 = Upp1+ll1*n;
    
    ll2 = -n'*Upp2-pl(4);
    Uplane2 = Upp2+ll2*n;

    sc = norm(Uplane-Upp)/norm(-18.8-Ucc(3));

    R = [null(n'), n]; if det(R)<0,R=[R(:,2),R(:,1),R(:,3)];end
    n2ii=cross(Upp1-Upp2,n);n2ii=n2ii/norm(n2ii);
    tmp = R'*n2ii;
    tmp(3)=0;tmp=tmp/norm(tmp);
    th2 = atan2(tmp(1),tmp(2));
    
    if ii==nbrpoints_anno+31,
        th2 = th2 + 3*pi/180;
    end
    R = R*[cos(th2),sin(th2),0;-sin(th2),cos(th2),0;0,0,1];
    
    tt = Uplane - sc*R*[3.75;cos(th)*2.0;-18.8];
%    tt = Uplane1 - sc*R*[0,7.0,-18.8]';
    T = [sc*R,tt;[0,0,0,1]];

    Utmp=T(1:3,:)*pextend(Usaft);

    triobj = [triobj,trisaft+size(Uobj,2)];
    Uobj=[Uobj,Utmp];
    instance_labels=[instance_labels,instance_cnt*ones(1,size(trisaft,2))];
end

%three packages in random position
pl = [n;-n'*mesh.shelves(2).U(:,1)-0.0001];
class_labels = [class_labels,4,5,5];
for ii=nbrpoints_anno+[40:3:45],
    Upp1 = U(1:3,ii);
    Upp2 = U(1:3,ii+1);
    Upp = U(1:3,ii+2);
    
    instance_cnt=instance_cnt+1;
        
    ll = -n'*Upp-pl(4);
    Uplane = Upp+ll*n;
    
    ll1 = -n'*Upp1-pl(4);
    Uplane1 = Upp1+ll1*n;
    
    ll2 = -n'*Upp2-pl(4);
    Uplane2 = Upp2+ll2*n;

    sc = norm(Uplane-Upp)/norm(-18.8-Ucc(3));

    R = [null(n'), n]; if det(R)<0,R=[R(:,2),R(:,1),R(:,3)];end
    n2ii=cross(Upp1-Upp2,n);n2ii=n2ii/norm(n2ii);
    tmp = R'*n2ii;
    tmp(3)=0;tmp=tmp/norm(tmp);
    th2 = atan2(tmp(1),tmp(2));
    
    R = R*[cos(th2),sin(th2),0;-sin(th2),cos(th2),0;0,0,1];
    
    tt = Uplane - sc*R*[3.75;cos(th)*2.0;-18.8];
    T = [sc*R,tt;[0,0,0,1]];

    Utmp=T(1:3,:)*pextend(Usaft);

    triobj = [triobj,trisaft+size(Uobj,2)];
    Uobj=[Uobj,Utmp];
    instance_labels=[instance_labels,instance_cnt*ones(1,size(trisaft,2))];
end









alpha = 0:0.4:2*pi;rr = 0.24;height=1;nn=length(alpha);
Ubottle=[rr*cos(alpha),rr*cos(alpha),0;rr*sin(alpha),rr*sin(alpha),0;zeros(size(alpha)),height*ones(size(alpha)),1];
tribottle = [1:nn,      nn+1:2*nn, 2*nn+1*ones(1,nn) ; ...
             [2:nn,1],  [nn+2:2*nn,nn+1]  , nn+1:2*nn, ;...
             nn+1:2*nn, [2:nn,1]       , [nn+2:2*nn,nn+1]];
%figure(1);clf;trisurf(tribottle',Ubottle(1,:),Ubottle(2,:),Ubottle(3,:));axis equal;rotate3d on;



%plane of coke bottles
v1 = mesh.shelves(1).U(:,2)-mesh.shelves(1).U(:,1);
v2 = mesh.shelves(1).U(:,7)-mesh.shelves(1).U(:,2);

n = cross(v1,v2);n= n/norm(n);
pl = [n;-n'*mesh.shelves(1).U(:,1)];


Utop = U(1:3,nbrpoints_anno+[46:69]);
[uu,ss,vv]=svd(pextend(Utop)');
toppl = vv(:,4);
toppl = toppl/norm(toppl(1:3));

for ii=nbrpoints_anno+[46:69],
    Upp = U(1:3,ii);
    if ii==nbrpoints_anno+46 || ii==nbrpoints_anno+51,
        Upp = U(1:3,ii)+0.06*(U(1:3,ii+6)-U(1:3,ii));
    end
    if ii==nbrpoints_anno+47 || ii==nbrpoints_anno+49 || ii==nbrpoints_anno+50,
        Upp = U(1:3,ii)+0.03*(U(1:3,ii+6)-U(1:3,ii));
    end
    ll = -toppl(1:3)'*Upp-toppl(4);
    Upp = Upp+ll*toppl(1:3);
    
    
    instance_cnt=instance_cnt+1;
    class_labels(instance_cnt) = 3; %cocacola can 33 cl
    ll = -n'*Upp-pl(4);
    Uplane = Upp+ll*n;

    sc = norm(Uplane-Upp);

    R = [null(n'), n]; if det(R)<0,R=[R(:,2),R(:,1),R(:,3)];end
    T = [sc*R,Uplane;[0,0,0,1]];

    Utmp=T(1:3,:)*pextend(Ubottle);

    triobj = [triobj,tribottle+size(Uobj,2)];
    Uobj=[Uobj,Utmp];
    instance_labels=[instance_labels,instance_cnt*ones(1,size(tribottle,2))];
end

    



figure(1);clf;trisurf(tri',mesh.shelves(1).U(1,:),mesh.shelves(1).U(2,:),mesh.shelves(1).U(3,:));axis equal;rotate3d on;hold on;
trisurf(triobj',Uobj(1,:),Uobj(2,:),Uobj(3,:));


pause;
         
         

for imindex = 1:48,imindex
    annotate_plot(settings,P_uncalib,imindex, tri, Utri, triobj, Uobj, instance_labels);
    pause
    close(imindex);
end

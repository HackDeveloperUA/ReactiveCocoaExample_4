//
//  ViewController.m
//  ReactiveCocoaExample_4
//
//  Created by Uber on 28/06/2017.
//  Copyright © 2017 Uber. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface ViewController ()
@property (nonatomic, strong) NSString* query;
@end

@implementation ViewController


#pragma mark - Helpers methods

- (void) preSetting {
     self.query = @"query";
}


#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self preSetting];

    
    RACSignal* firstSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
       
        for (int i=0; i<=10; i++) {
            [subscriber sendNext:[NSString stringWithFormat:@"Привет firstSignal next = %d",i]];
        }
        [subscriber sendCompleted];
        return nil;
    }];
    

    // Operation Injection
    
    // - doNext
    // - doNext будет вызыватся перед каждым sendNext
    [[firstSignal doNext:^(id x) {
        NSLog(@"firstSignal doNext");
    }]subscribeNext:^(NSString* greetingLine) {
        NSLog(@"%@",greetingLine);
    } completed:^{
        NSLog(@"firstSignal completed\n\n");
    }];
    
    
    
    
    RACSignal* secondSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@"Начинаем 1..2..3..."];
        
        NSError *err = [NSError errorWithDomain:@"Ой, что-то пошло не так" code:100 userInfo:nil];
        [subscriber sendError:err];
        return nil;
    }];
    
    // - doError
    // - doCompleted
    [[[[secondSignal doNext:^(id x) {
        NSLog(@"secondSignal doNext");
    }] doError:^(NSError *error) {
        NSLog(@"secondSignal doError");
    }] doCompleted:^{
        NSLog(@"secondSignal doCompleted");
        }]
        subscribeNext:^(id x) {
            NSLog(@"secondSignal subscribeNext= %@",x);
        }
        error:^(NSError *error) {
            NSLog(@"secondSignal error= %@\n\n",error);
        }
        completed:^{
            NSLog(@"secondSignal completed\n\n");
        }];
    
    
    
    // Operation Transformation
    //
    // map - возвращает Array блок который вызывается по отношению к каждому объекту, с целью изменить его
    // filter - возвращает Array содержащий объекты которые отвечают какому либо if`у. Например все люди старше 18 лет
    // reduce - всегда возвращает одно значение. Например сумму всех элементов массива
    // zip    - соединяет два сигнала, посылая первое значение из перового сигнала, потом первое знач. из второго ит.д.
     NSArray* arrAges = @[@10, @24, @6, @40, @14, @19, @21];

    // - filter
    NSArray* peopleOveAge18 = [[arrAges.rac_sequence filter:^BOOL(NSNumber* age) {
                                  return [age integerValue] > 18;
                               }] array];
    
    // - map
    NSArray* hasBeen10Years = [[arrAges.rac_sequence map:^id(NSNumber* age) {
                                return [NSString stringWithFormat:@"Was: %d age | Became: %d age",[age integerValue],
                                                                                                  [age integerValue]+10];
                              }] array];
    
    // - reduce
    NSInteger sumAge = [[arrAges.rac_sequence  foldLeftWithStart:@0 reduce:^id(NSNumber* accumulator, NSNumber* value) {
       return @(accumulator.integerValue + value.integerValue);
    }] integerValue];
    NSInteger averageAge = sumAge/arrAges.count;
    
    
    NSLog(@"peopleOveAge18 = %@\n\n",peopleOveAge18);
    NSLog(@"hasBeen10Years = %@\n\n",hasBeen10Years);
    NSLog(@"averageAge = %d\n\n",averageAge);

    
    /* zip -
     
            Signal A | -(a0)-------------(a1)-----x
            |
            Signal B | ----(b0)-(b1)-(b2)----(b3)--->
            |
            zip:A,B | ----(a0,b0)-------(a1,b1)--x
            |
            +-------------------------------
                        -- Time -->
    */
    
    /* combineLatest
     
            Signal A | -(a0)-----------------------(a1)-----x
            |
            Signal B | ----(b0)----(b1)----(b2)------------(b3)---->
            |
            cl/r:A,B | ----(a0,b0)-(a0,b1)-(a0,b2)-(a1,b2)-(a1,b3)->
            |
            +----------------------------------------------
                    -- Time -->
     */
    // goo.gl/AZwPbh
    
    NSArray* arrA = @[@"a0", @"a1"];
    NSArray* arrB = @[@"b0", @"b1", @"b2", @"b3"];
    
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    
    RACSignal *combined = [RACSignal
                           zip:@[ letters, numbers ]
                           reduce:^(NSString *letter, NSString *number) {
                               return [letter stringByAppendingString:number];
                           }];
    
    // Outputs: A1 B2 C3 D4
    [combined subscribeNext:^(id x) {
        NSLog(@"%@\n", x);
    }];
    
    [letters sendNext:@"A"];
    [letters sendNext:@"B"];
    
    [numbers sendNext:@"1"];
    [numbers sendNext:@"2"];
    
    [letters sendNext:@"C"];
    [numbers sendNext:@"3"];
    
    [letters sendNext:@"D"];
    [numbers sendNext:@"4"];
    
    

    // Operation Combining
    //
    // - merge - Принимает массив сигналов, и возвращает свой сигнал, когда вся группа завершила работу,
    //           например, можно продолжить работу только тогда, когда все остальные уже законичли работу.
    //           например собрать патрон мы может только если один сигнал полностью создаст массив пуль, а
    //           а второй сигнал создал массив гильз, и только теперь можно соединить и получить пулю
    // - concat - Продуценты должны быть объединены, чтобы их значения отправлялись в порядке самих продуцентов.
    //            в каком порядке положим в массив сигналы, в таком они и будут выполняться
    // - then
    
 
    // - merge
    [[RACSignal   merge:@[ [self fetchUserRepos], [self fetchOrgRepos]] ]
      subscribeNext:^(id x) {
          NSLog(@"x=%@",x);

      } completed:^{
          NSLog(@"They're both done! - merge\n\n");
      }];
    

    // - concat
    [[RACSignal concat:@[ [self fetchUserRepos], [self fetchOrgRepos]] ]
     subscribeNext:^(id x) {
         NSLog(@"x=%@",x);

     } completed:^{
         NSLog(@"They're both done! - concat\n\n");
     }];
    

    
    
    // Operation Combining
    // - take:2   - Примет только первые два сигнала
    // - skip     - указываем при создании сигнала, и какое число будет, такое число исходящих сигналов мы и не получим
    // - throttle - задает указаное время, в течение которого сигналы излучаться не будут
    // - distinctUntilChanged - гарантирует что следующие значение не будет таким же как и преведущие, но через одно и более значения могут совпадать
    
   RACSignal* thirdSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      
       [subscriber sendNext:@"Попытка 1"];
       [subscriber sendNext:@"Попытка 2"];
       [subscriber sendNext:@"Попытка 3"];
       [subscriber sendNext:@"Попытка 4"];
       [subscriber sendNext:@"Попытка 5"];

       [subscriber sendCompleted];
       return nil;
   }] skip:2];
    
    [thirdSignal subscribeNext:^(id x) {
        // Будет выводиться с третий "попытки"
        NSLog(@"%@",x);
    }];
    
    
    
    [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@"Вау 1"];
        [subscriber sendNext:@"Вау 1"];
        [subscriber sendNext:@"Вау 2"];
        [subscriber sendNext:@"Вау 3"];
        [subscriber sendNext:@"Вау 1"];
        [subscriber sendNext:@"Вау 1"];
        [subscriber sendCompleted];
        return nil;
    }] distinctUntilChanged]
     
    subscribeNext:^(id x) {
        NSLog(@"%@",x);

    } completed:^{
        NSLog(@"\n\n\n");
    }];
}










#pragma mark - Reactive methods

- (RACSignal*) fetchUserRepos {
    
    return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSInteger count = 0;
        for (int i=0; i<=5; i++) {
            NSLog(@"fetching user repositories...");
            if (i%2==1)
                [subscriber sendNext:@"NEXT FROM FETCH_user_REPOS"];

            count++;
        }
        [subscriber sendCompleted];
        return nil;
    }];
}



- (RACSignal*) fetchOrgRepos {
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSInteger count = 0;
        for (int i=0; i<=5; i++) {
            NSLog(@"fetching org repositories...");
            if (i%2==0)
            [subscriber sendNext:@"NEXT FROM FETCH_ORG_REPOS"];
            count++;
        }
        [subscriber sendCompleted];
        return nil;
    }];
}


@end

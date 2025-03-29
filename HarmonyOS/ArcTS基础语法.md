# 编程语言介绍
## 什么是 ArkTS
ArkTS 是 HarmonyOS 应用开发语言
- ArkTS 提供了声明式 UI 范式、状态管理支持等相应的能力，让开发者可以以更简洁、更自然的方式开发应用。
- 在保持 TypeScript（简称 TS）基本语法风格的基础上，进一步通过规范强化静态检查和分析，使得在程序运行之前的开发期能检测更多错误，提升代码健壮性，并实现更好的运行性能，ArkTS 同时也支持与 TS/JS 高效互操作。
- 针对JS/TS并发能力支持有限的问题，ArkTS对并发编程API和能力进行了增强。
- 未来，ArkTS也会结合应用开发/运行的需求持续演进，逐步提供并发能力增强、系统类型增强、分布式开发范式等更多特性。
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322225657815.png)

## ArcTS 基于 TypeScript 的增强
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322225845651.png)
### 规范的代码更好地保证正确性和性能
1、强化静态类型检查：ArkTS 要求所有类型在程序实际运行前都是已知的，减少运行时的类型检测，提升性能
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322225928408.png)
2、禁止在运行时改变对象布局：为实现最大性能，ArkTS 要求在程序执行期间不能更改对象布局
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322230136010.png)
3、基于原型的继承：ArkTS 没有原型的概念，不支持在原型上赋值或继承
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322230458453.png)
## ArkTS 对 UI 范式的支持
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322230525214.png)
# 基本知识
## 声明
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322230621737.png)
## 类型
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322230656632.png)
### 基本类型 ：string、number、boolean、null、undefined、bigint 等
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322230728917.png)
console.log 参数默认为 string 类型，其他类型需要转换后输出
### 引用类型：Interface、Object、Function、Array、Class、Tuple 等
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322230946198.png)
interface 接口定义对象的结构，描述对象的属性和方法
object 是一种键值集合，可使用构造函数或字面量的方式进行初始化
class 是一种特殊的对象
instance 类实例可以使用 new 或构造函数进行初始化
tuple 元组用于表示固定数量和类型的元素组合
### 枚举类型：Enum
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322231511182.png)
### 联合类型：Union
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322232226359.png)
允许变量在多个类型中切换
### 类型别名：Type Aliases
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322232319306.png)
### 空安全
一般来说，有时会存在声明变量时不确定初始值。在这类情况下，通常使用联合类型包含 null 值
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322233010440.png)
### 类型安全与类型推断
ArkTS 是类型安全的语言，编辑器会进行类型检查，实时提示错误信息
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322233127429.png)
ArkTS 支持自动类型推导，没有指定类型时，ArkTS 支持使用类型推断自动选择合适的类型
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322233203595.png)
## 语句
语句是控制程序分支运行的指令
### 条件语句
用于基于不同的条件来执行不同的动作，根据判断条件的执行结果（true 或 false）来决定执行的代码块。
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322233349971.png)
### 条件表法式
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322233420114.png)
### 循环语句
用于重复执行相同的一组语句，提高效率、简化代码
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322233521182.png)
# 函数的声明和使用
函数是一组一起执行多条语句的组合，形成可重用的代码块
通过 function 关键字声明要告诉编译器函数的名称、返回类型和参数以及执行的内容
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322234031343.png)
### 参数
- 必选参数：必须要传入的参数
- 可选参数：参数是可选的，即在调用函数时可以选择性传入的参数
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322234201177.png)
- 默认参数：允许开发者为参数指定默认值，在调用函数时若未传递相应的参数，则使用默认值
- 剩余参数：允许开发者将函数的多个独立参数收集起来，并打包成一个数组
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322234359974.png)
### 箭头函数/lambda 表达式
简化函数声明，通常用于需要一个简单函数的地方
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322234650615.png)
### 闭包函数
一个函数可以将另一个函数当做返回值，保留对内部作用域的访问
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322235334945.png)
### 函数类型
将一个函数声明定义为一个类型，函数参数或者返回值
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322235422718.png)
# 类的声明和使用
类的声明描述了所创建的对象共同的属性和方法
ArkTS 支持基于类的面向对象的编程方式，定义类的关键字为 clasS，后面紧跟类名
## 类的创建
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250322235953013.png)
## 构造器
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323000116410.png)
## 方法
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323000142328.png)
## 封装
> 面向对象三大特征：
> 封装、继承、多态

将数据隐藏起来，只对外部提供必要的接口来访问和操作数据，确保数据的一致性和安全性
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323000228704.png)
## 继承
子类继承父类的特征和行为，使得子类具有父类相同的行为
ArkTS 中允许使用继承来扩展现有的类，对应的关键字为 extends
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323000456410.png)
## 多态
子类继承父类，并可以重写父类方法，使不同的实例对象对同一行为有不同的表现
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323000534833.png)
# 接口的声明和使用
接口是可以用来约束和规范类的方法，提高开发效率的工具，接口在程序设计中具有非常重要的作用
## 接口的声明
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323000818278.png)
extends 对接口进行扩展，添加新的属性
使用接口创建实例：
1. 对于只有属性的接口，可以使用字面量的形式创建对象实例
2. 如果接口中声明了方法则无法使用字面量的形式创建对象实例
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323001050850.png)
## 接口的实现
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323001238079.png)
# 命名空间的概念和使用
一种将代码组织为不同区域的方式，用来更好地控制命名冲突和组织代码
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323001352678.png)
使用 export 关键字导出接口或类型、方法，使之可以在命名空间外部被访问
# 模块导入与导出
一个 ArkTS 文件的作用域是独立的
由于不同文件之间的作用域是隔离的，一个文件如果想引用其它文件的函数、类或者变量，就需要使用 export 和 import 进行模块的导入和导出
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323001720512.png)
## export
通过export导出一个文件的类、变量、函数等
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323001833346.png)
## import
通过 import 导入另一个文件的变量、函数、类等
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323001915414.png)
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323001928112.png)
## 重新导出 export from
export from 用于从一个模块中导出所有的导出项，或从一个模块中导出多个特定的导出项
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323002044852.png)
在 Util 文件中导出特定导出项，在 Index 中导出 Util 中所有导出项，这样 Page 在引入 Index 时就可以导出 Util 中的所有导出项
## 动态 import
动态 import 支持条件延迟加载，支持部分反射功能，可以提升页面的加载速度
因为被导入的模块在加载时并不存在，需要异步获取，当需要按需或按条件导入模块时使用动态 import
![image.png](https://notes-ming.oss-cn-beijing.aliyuncs.com/images/20250323002850275.png)
